using System;

namespace Schedule.Domain.Exceptions;

public class ConcurrencyConflictException()
    : Exception("The operation conflicted with a concurrent change. Please try again.");
