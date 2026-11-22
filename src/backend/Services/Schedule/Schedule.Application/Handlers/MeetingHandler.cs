using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using ErrorOr;
using Schedule.Application.Common;
using Schedule.Application.DTOs;
using Schedule.Domain.Entities;
using Schedule.Domain.Enums;
using Schedule.Domain.Exceptions;
using Schedule.Domain.Interfaces;

namespace Schedule.Application.Handlers;

public class MeetingHandler
{
    private readonly IMeetingRepository _repository;
    private readonly IOfficeHourRepository _officeHourRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly CampusTimeZone _timeZone;

    public MeetingHandler(
        IMeetingRepository repository,
        IOfficeHourRepository officeHourRepository,
        IUnitOfWork unitOfWork,
        CampusTimeZone timeZone)
    {
        _repository = repository;
        _officeHourRepository = officeHourRepository;
        _unitOfWork = unitOfWork;
        _timeZone = timeZone;
    }

    public async Task<ErrorOr<MeetingDto>> GetByIdAsync(Guid id, Requester requester, CancellationToken cancellationToken)
    {
        var meeting = await _repository.GetByIdAsync(id, cancellationToken);
        if (meeting is null) return Error.NotFound(description: $"Meeting '{id}' not found.");
        if (!IsParticipantOrAdmin(requester, meeting.TeacherRefId, meeting.StudentRefId))
            return Error.Forbidden(description: "Only the student, the teacher of the meeting or an administrator can see it.");
        return MeetingDto.FromEntity(meeting);
    }

    // Administrators get every meeting; anyone else only the meetings they take part in.
    public async Task<ErrorOr<IEnumerable<MeetingDto>>> GetAllAsync(Requester requester, CancellationToken cancellationToken)
    {
        var meetings = requester.IsAdmin
            ? await _repository.GetAllAsync(cancellationToken)
            : await _repository.GetByParticipantAsync(requester.UserId, cancellationToken);
        return ErrorOrFactory.From(meetings.Select(MeetingDto.FromEntity));
    }

    public async Task<ErrorOr<IEnumerable<MeetingDto>>> GetByTeacherAsync(Guid teacherRefId, DateTime from, DateTime to, CancellationToken cancellationToken)
    {
        (from, to) = (ScheduleTime.ToUtc(from), ScheduleTime.ToUtc(to));
        if (to <= from) return Error.Validation(description: "The 'to' parameter must be later than 'from'.");
        var meetings = await _repository.GetByTeacherAsync(teacherRefId, from, to, cancellationToken);
        return ErrorOrFactory.From(meetings.Select(MeetingDto.FromEntity));
    }

    public async Task<ErrorOr<MeetingDto>> CreateAsync(CreateMeetingRequest request, Requester requester, CancellationToken cancellationToken)
    {
        if (!IsParticipantOrAdmin(requester, request.TeacherRefId, request.StudentRefId))
            return Error.Forbidden(description: "Only the student, the teacher of the meeting or an administrator can book it.");

        Meeting meeting;
        try
        {
            meeting = new Meeting(request.TeacherRefId, request.StudentRefId, request.StructureRefId, ScheduleTime.ToUtc(request.ScheduledAt), request.DurationMinutes);
        }
        catch (ArgumentException ex) { return Error.Validation(description: ex.Message); }

        if (!await IsInsideOfficeHoursAsync(meeting, cancellationToken))
            return Error.Validation(description: "The meeting must be inside one of the teacher's office hours.");

        try
        {
            return await _unitOfWork.ExecuteInTransactionAsync<ErrorOr<MeetingDto>>(async () =>
            {
                var overlapping = await _repository.GetActiveOverlappingAsync(
                    meeting.TeacherRefId, meeting.StudentRefId, meeting.StructureRefId,
                    meeting.ScheduledAt, meeting.EndsAt, cancellationToken);

                var conflict = DescribeConflict(meeting, overlapping);
                if (conflict is not null) return Error.Conflict(description: conflict);

                await _repository.AddAsync(meeting, cancellationToken);
                return MeetingDto.FromEntity(meeting);
            }, cancellationToken);
        }
        catch (ConcurrencyConflictException)
        {
            return Error.Conflict(description: "The time slot was just booked by another request. Please try again.");
        }
    }

    public async Task<ErrorOr<MeetingDto>> UpdateStatusAsync(Guid id, string status, Guid requesterRefId, CancellationToken cancellationToken)
    {
        var target = ParseTargetStatus(status);
        if (target is null) return Error.Validation(description: "The status must be Confirmed, Cancelled or Completed.");
        return await ChangeStatusAsync(id, target.Value, requesterRefId, cancellationToken);
    }

    // Deleting a meeting cancels it: it is kept with Cancelled status and its slot is freed.
    public async Task<ErrorOr<Deleted>> CancelAsync(Guid id, Guid requesterRefId, CancellationToken cancellationToken)
    {
        var result = await ChangeStatusAsync(id, MeetingStatus.Cancelled, requesterRefId, cancellationToken);
        return result.IsError ? result.Errors : Result.Deleted;
    }

    public async Task<ErrorOr<MeetingDto>> RescheduleAsync(Guid id, RescheduleMeetingRequest request, Guid requesterRefId, CancellationToken cancellationToken)
    {
        var meeting = await _repository.GetByIdAsync(id, cancellationToken);
        if (meeting is null) return Error.NotFound(description: $"Meeting '{id}' not found.");
        if (requesterRefId != meeting.TeacherRefId && requesterRefId != meeting.StudentRefId)
            return Error.Forbidden(description: "Only the student or the teacher of the meeting can reschedule it.");
        if (!meeting.IsActive)
            return Error.Conflict(description: "Only a pending or confirmed meeting can be rescheduled.");

        // The new slot is checked on a copy so the meeting is only changed once every rule passes.
        Meeting candidate;
        try
        {
            candidate = new Meeting(meeting.TeacherRefId, meeting.StudentRefId, request.StructureRefId, ScheduleTime.ToUtc(request.ScheduledAt), request.DurationMinutes);
        }
        catch (ArgumentException ex) { return Error.Validation(description: ex.Message); }

        if (!await IsInsideOfficeHoursAsync(candidate, cancellationToken))
            return Error.Validation(description: "The meeting must be inside one of the teacher's office hours.");

        try
        {
            return await _unitOfWork.ExecuteInTransactionAsync<ErrorOr<MeetingDto>>(async () =>
            {
                var overlapping = await _repository.GetActiveOverlappingAsync(
                    candidate.TeacherRefId, candidate.StudentRefId, candidate.StructureRefId,
                    candidate.ScheduledAt, candidate.EndsAt, cancellationToken);

                var conflict = DescribeConflict(candidate, overlapping.Where(m => m.Id != meeting.Id).ToList());
                if (conflict is not null) return Error.Conflict(description: conflict);

                meeting.Reschedule(candidate.StructureRefId, candidate.ScheduledAt, candidate.DurationMinutes);
                await _repository.UpdateAsync(meeting, cancellationToken);
                return MeetingDto.FromEntity(meeting);
            }, cancellationToken);
        }
        catch (ConcurrencyConflictException)
        {
            return Error.Conflict(description: "The time slot was just booked by another request. Please try again.");
        }
    }

    private async Task<ErrorOr<MeetingDto>> ChangeStatusAsync(Guid id, MeetingStatus target, Guid requesterRefId, CancellationToken cancellationToken)
    {
        var meeting = await _repository.GetByIdAsync(id, cancellationToken);
        if (meeting is null) return Error.NotFound(description: $"Meeting '{id}' not found.");

        var isTeacher = requesterRefId == meeting.TeacherRefId;
        if (!isTeacher && requesterRefId != meeting.StudentRefId)
            return Error.Forbidden(description: "Only the student or the teacher of the meeting can change its status.");

        if (!isTeacher && target != MeetingStatus.Cancelled)
            return Error.Forbidden(description: "Only the teacher of the meeting can confirm or complete it.");

        try
        {
            ApplyStatus(meeting, target);
        }
        catch (InvalidOperationException ex) { return Error.Conflict(description: ex.Message); }

        await _repository.UpdateAsync(meeting, cancellationToken);
        return MeetingDto.FromEntity(meeting);
    }

    private async Task<bool> IsInsideOfficeHoursAsync(Meeting meeting, CancellationToken cancellationToken)
    {
        var officeHours = await _officeHourRepository.GetByTeacherAsync(meeting.TeacherRefId, cancellationToken);
        return OfficeHourCoverage.Covers(officeHours, meeting, _timeZone);
    }

    private static bool IsParticipantOrAdmin(Requester requester, Guid teacherRefId, Guid studentRefId) =>
        requester.CanAccess(teacherRefId) || requester.CanAccess(studentRefId);

    private static MeetingStatus? ParseTargetStatus(string status) => status.ToLowerInvariant() switch
    {
        "confirmed" => MeetingStatus.Confirmed,
        "cancelled" => MeetingStatus.Cancelled,
        "completed" => MeetingStatus.Completed,
        _ => null
    };

    private static void ApplyStatus(Meeting meeting, MeetingStatus target)
    {
        switch (target)
        {
            case MeetingStatus.Confirmed:
                meeting.Confirm();
                break;
            case MeetingStatus.Completed:
                meeting.Complete();
                break;
            default:
                meeting.Cancel();
                break;
        }
    }

    private static string? DescribeConflict(Meeting meeting, IReadOnlyList<Meeting> overlapping)
    {
        if (overlapping.Any(m => m.TeacherRefId == meeting.TeacherRefId))
            return "The teacher already has a meeting at that time.";

        if (overlapping.Any(m => m.StudentRefId == meeting.StudentRefId))
            return "The student already has a meeting at that time.";

        if (overlapping.Any(m => m.StructureRefId == meeting.StructureRefId))
            return "The room is already booked at that time.";

        return null;
    }
}
