using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using ErrorOr;
using Schedule.Application.DTOs;
using Schedule.Domain.Entities;
using Schedule.Domain.Exceptions;
using Schedule.Domain.Interfaces;

namespace Schedule.Application.Handlers;

public class MeetingHandler
{
    private readonly IMeetingRepository _repository;
    private readonly IUnitOfWork _unitOfWork;

    public MeetingHandler(IMeetingRepository repository, IUnitOfWork unitOfWork)
    {
        _repository = repository;
        _unitOfWork = unitOfWork;
    }

    public async Task<ErrorOr<MeetingDto>> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var meeting = await _repository.GetByIdAsync(id, cancellationToken);
        if (meeting is null) return Error.NotFound(description: $"Meeting '{id}' not found.");
        return MeetingDto.FromEntity(meeting);
    }

    public async Task<ErrorOr<IEnumerable<MeetingDto>>> GetAllAsync(CancellationToken cancellationToken)
    {
        var meetings = await _repository.GetAllAsync(cancellationToken);
        return ErrorOrFactory.From(meetings.Select(MeetingDto.FromEntity));
    }

    public async Task<ErrorOr<IEnumerable<MeetingDto>>> GetByTeacherAsync(Guid teacherRefId, DateTime from, DateTime to, CancellationToken cancellationToken)
    {
        if (to <= from) return Error.Validation(description: "The 'to' parameter must be later than 'from'.");
        var meetings = await _repository.GetByTeacherAsync(teacherRefId, from, to, cancellationToken);
        return ErrorOrFactory.From(meetings.Select(MeetingDto.FromEntity));
    }

    public async Task<ErrorOr<MeetingDto>> CreateAsync(CreateMeetingRequest request, CancellationToken cancellationToken)
    {
        Meeting meeting;
        try
        {
            meeting = new Meeting(request.TeacherRefId, request.StudentRefId, request.StructureRefId, request.ScheduledAt, request.DurationMinutes);
        }
        catch (ArgumentException ex) { return Error.Validation(description: ex.Message); }

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
