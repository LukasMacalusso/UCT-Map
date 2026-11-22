using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using ErrorOr;
using Schedule.Application.Common;
using Schedule.Application.DTOs;
using Schedule.Domain.Interfaces;

namespace Schedule.Application.Handlers;

public class TeacherHandler
{
    private readonly IOfficeHourRepository _officeHourRepository;
    private readonly IMeetingRepository _meetingRepository;

    public TeacherHandler(IOfficeHourRepository officeHourRepository, IMeetingRepository meetingRepository) { _officeHourRepository = officeHourRepository; _meetingRepository = meetingRepository; }

    public async Task<ErrorOr<TeacherWorkloadDto>> GetWorkloadAsync(Guid teacherRefId, DateTime from, DateTime to, Requester requester, CancellationToken cancellationToken)
    {
        if (!requester.CanAccess(teacherRefId)) return Error.Forbidden(description: "Only the teacher or an administrator can see this workload.");
        (from, to) = (ScheduleTime.ToUtc(from), ScheduleTime.ToUtc(to));
        if (to <= from) return Error.Validation(description: "The 'to' parameter must be later than 'from'.");
        var officeHours = await _officeHourRepository.GetByTeacherAsync(teacherRefId, cancellationToken);
        var meetings = await _meetingRepository.GetByTeacherAsync(teacherRefId, from, to, cancellationToken);
        var weeklyOfficeHourMinutes = officeHours.Sum(officeHour => (int)(officeHour.EndTime - officeHour.StartTime).TotalMinutes);
        var dto = new TeacherWorkloadDto(teacherRefId, from, to, weeklyOfficeHourMinutes, meetings.Count, officeHours.Select(OfficeHourDto.FromEntity).ToList(), meetings.Select(MeetingDto.FromEntity).ToList());
        return dto;
    }

    public async Task<ErrorOr<TeacherAvailabilityDto>> GetAvailabilityAsync(Guid teacherRefId, CancellationToken cancellationToken)
    {
        var officeHours = await _officeHourRepository.GetByTeacherAsync(teacherRefId, cancellationToken);
        return new TeacherAvailabilityDto(teacherRefId, officeHours.Select(OfficeHourDto.FromEntity).ToList());
    }
}
