FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app

EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src


COPY ["src/backend/Services/Campus/Campus.API/Campus.API.csproj", "Campus.API/"]
COPY ["src/backend/Services/Campus/Campus.Application/Campus.Application.csproj", "Campus.Application/"]
COPY ["src/backend/Services/Campus/Campus.Domain/Campus.Domain.csproj", "Campus.Domain/"]
COPY ["src/backend/Services/Campus/Campus.Infrastructure/Campus.Infrastructure.csproj", "Campus.Infrastructure/"]

RUN dotnet restore "Campus.API/Campus.API.csproj"

COPY ["src/backend/Services/Campus/", "./"]
WORKDIR "/src/Campus.API"
RUN dotnet build "Campus.API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Campus.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
USER $APP_UID
ENTRYPOINT ["dotnet", "Campus.API.dll"]


