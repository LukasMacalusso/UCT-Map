using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using ErrorOr;
using Schedule.Application.Common;
using Schedule.Application.DTOs;
using Schedule.Domain.Entities;
using Schedule.Domain.Exceptions;
using Schedule.Domain.Interfaces;

namespace Schedule.Application.Handlers;

public class OfficeHourHandler
{
    private readonly IOfficeHourRepository _repository;
    private readonly IMeetingRepository _meetingRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly CampusTimeZone _timeZone;
    private readonly TimeProvider _timeProvider;

    private static readonly Error OnlyTeachersCanManage =
        Error.Forbidden(description: "Only teachers and administrators can manage office hours.");

    public OfficeHourHandler(
        IOfficeHourRepository repository,
        IMeetingRepository meetingRepository,
        IUnitOfWork unitOfWork,
        CampusTimeZone timeZone,
        TimeProvider timeProvider)
    {
        _repository = repository;
        _meetingRepository = meetingRepository;
        _unitOfWork = unitOfWork;
        _timeZone = timeZone;
        _timeProvider = timeProvider;
    }

    public async Task<ErrorOr<OfficeHourDto>> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var officeHour = await _repository.GetByIdAsync(id, cancellationToken);
        if (officeHour is null) return Error.NotFound(description: $"Office hour '{id}' not found.");
        return OfficeHourDto.FromEntity(officeHour);
    }

    public async Task<ErrorOr<IEnumerable<OfficeHourDto>>> GetAllAsync(CancellationToken cancellationToken)
    {
        var officeHours = await _repository.GetAllAsync(cancellationToken);
        return ErrorOrFactory.From(officeHours.Select(OfficeHourDto.FromEntity));
    }

    public async Task<ErrorOr<IEnumerable<OfficeHourDto>>> GetByTeacherAsync(Guid teacherRefId, CancellationToken cancellationToken)
    {
        var officeHours = await _repository.GetByTeacherAsync(teacherRefId, cancellationToken);
        return ErrorOrFactory.From(officeHours.Select(OfficeHourDto.FromEntity));
    }

    public async Task<ErrorOr<OfficeHourDto>> CreateAsync(CreateOfficeHourRequest request, Requester requester, CancellationToken cancellationToken)
    {
        if (!requester.CanManageOfficeHours) return OnlyTeachersCanManage;
        if (!requester.CanAccess(request.TeacherRefId))
            return Error.Forbidden(description: "Only the teacher or an administrator can create office hours for this teacher.");

        OfficeHour officeHour;
        try
        {
            officeHour = new OfficeHour(request.TeacherRefId, request.StructureRefId, request.DayOfWeek, request.StartTime, request.EndTime);
        }
        catch (ArgumentException ex) { return Error.Validation(description: ex.Message); }

        try
        {
            return await _unitOfWork.ExecuteInTransactionAsync<ErrorOr<OfficeHourDto>>(async () =>
            {
                var overlapping = await _repository.GetOverlappingAsync(
                    officeHour.TeacherRefId, officeHour.StructureRefId,
                    officeHour.DayOfWeek, officeHour.StartTime, officeHour.EndTime, cancellationToken);

                var conflict = DescribeConflict(officeHour, overlapping);
                if (conflict is not null) return Error.Conflict(description: conflict);

                await _repository.AddAsync(officeHour, cancellationToken);
                return OfficeHourDto.FromEntity(officeHour);
            }, cancellationToken);
        }
        catch (ConcurrencyConflictException)
        {
            return Error.Conflict(description: "The time slot was just taken by another request. Please try again.");
        }
    }

    public async Task<ErrorOr<OfficeHourDto>> UpdateAsync(Guid id, UpdateOfficeHourRequest request, Requester requester, CancellationToken cancellationToken)
    {
        if (!requester.CanManageOfficeHours) return OnlyTeachersCanManage;
        var officeHour = await _repository.GetByIdAsync(id, cancellationToken);
        if (officeHour is null) return Error.NotFound(description: $"Office hour '{id}' not found.");
        if (!requester.CanAccess(officeHour.TeacherRefId))
            return Error.Forbidden(description: "Only the teacher or an administrator can change this office hour.");

        var previous = Snapshot(officeHour);
        try
        {
            officeHour.Update(request.StructureRefId, request.DayOfWeek, request.StartTime, request.EndTime);
        }
        catch (ArgumentException ex) { return Error.Validation(description: ex.Message); }

        try
        {
            return await _unitOfWork.ExecuteInTransactionAsync<ErrorOr<OfficeHourDto>>(async () =>
            {
                var overlapping = await _repository.GetOverlappingAsync(
                    officeHour.TeacherRefId, officeHour.StructureRefId,
                    officeHour.DayOfWeek, officeHour.StartTime, officeHour.EndTime, cancellationToken);

                var conflict = DescribeConflict(officeHour, overlapping.Where(o => o.Id != officeHour.Id).ToList());
                if (conflict is not null) return Error.Conflict(description: conflict);

                await _repository.UpdateAsync(officeHour, cancellationToken);
                await CancelMeetingsLeftOutsideAsync(previous, cancellationToken);
                return OfficeHourDto.FromEntity(officeHour);
            }, cancellationToken);
        }
        catch (ConcurrencyConflictException)
        {
            return Error.Conflict(description: "The time slot was just taken by another request. Please try again.");
        }
    }

    public async Task<ErrorOr<Deleted>> DeleteAsync(Guid id, Requester requester, CancellationToken cancellationToken)
    {
        if (!requester.CanManageOfficeHours) return OnlyTeachersCanManage;
        var officeHour = await _repository.GetByIdAsync(id, cancellationToken);
        if (officeHour is null) return Error.NotFound(description: $"Office hour '{id}' not found.");
        if (!requester.CanAccess(officeHour.TeacherRefId))
            return Error.Forbidden(description: "Only the teacher or an administrator can delete this office hour.");

        var previous = Snapshot(officeHour);
        try
        {
            return await _unitOfWork.ExecuteInTransactionAsync<ErrorOr<Deleted>>(async () =>
            {
                await _repository.RemoveAsync(officeHour, cancellationToken);
                await CancelMeetingsLeftOutsideAsync(previous, cancellationToken);
                return Result.Deleted;
            }, cancellationToken);
        }
        catch (ConcurrencyConflictException)
        {
            return Error.Conflict(description: "The office hour was just changed by another request. Please try again.");
        }
    }

    // Cascade: upcoming meetings that were inside the old block and no longer fit any block of the teacher are cancelled.
    private async Task CancelMeetingsLeftOutsideAsync(OfficeHour previous, CancellationToken cancellationToken)
    {
        var now = ScheduleTime.ToUtc(_timeProvider.GetUtcNow().UtcDateTime);
        var currentBlocks = await _repository.GetByTeacherAsync(previous.TeacherRefId, cancellationToken);
        var upcoming = await _meetingRepository.GetUpcomingByTeacherAsync(previous.TeacherRefId, now, cancellationToken);

        foreach (var meeting in upcoming)
        {
            if (!OfficeHourCoverage.Covers([previous], meeting, _timeZone)) continue;
            if (OfficeHourCoverage.Covers(currentBlocks, meeting, _timeZone)) continue;

            meeting.Cancel();
            await _meetingRepository.UpdateAsync(meeting, cancellationToken);
        }
    }

    private static OfficeHour Snapshot(OfficeHour officeHour) => new(
        officeHour.TeacherRefId, officeHour.StructureRefId, officeHour.DayOfWeek, officeHour.StartTime, officeHour.EndTime);

    private static string? DescribeConflict(OfficeHour officeHour, IReadOnlyList<OfficeHour> overlapping)
    {
        if (overlapping.Any(o => o.TeacherRefId == officeHour.TeacherRefId))
            return "The teacher already has an office hour at that time.";

        if (overlapping.Any(o => o.StructureRefId is not null && o.StructureRefId == officeHour.StructureRefId))
            return "The room already has an office hour at that time.";

        return null;
    }
}
