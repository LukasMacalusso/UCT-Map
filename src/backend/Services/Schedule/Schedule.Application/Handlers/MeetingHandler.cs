using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using ErrorOr;
using Schedule.Application.DTOs;
using Schedule.Domain.Entities;
using Schedule.Domain.Interfaces;

namespace Schedule.Application.Handlers;

public class MeetingHandler
{
    private readonly IMeetingRepository _repository;

    public MeetingHandler(IMeetingRepository repository) { _repository = repository; }

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
        var meeting = new Meeting(request.TeacherRefId, request.StudentRefId, request.StructureRefId, request.ScheduledAt, request.DurationMinutes);
        await _repository.AddAsync(meeting, cancellationToken);
        return MeetingDto.FromEntity(meeting);
    }
}
