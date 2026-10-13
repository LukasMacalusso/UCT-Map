FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY ["src/backend/ApiGateway/ApiGateway.API/ApiGateway.API.csproj", "ApiGateway.API/"]
RUN dotnet restore "ApiGateway.API/ApiGateway.API.csproj"

COPY ["src/backend/ApiGateway/ApiGateway.API/", "ApiGateway.API/"]
RUN dotnet publish "ApiGateway.API/ApiGateway.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080
COPY --from=build /app/publish .
USER $APP_UID
ENTRYPOINT ["dotnet", "ApiGateway.API.dll"]
