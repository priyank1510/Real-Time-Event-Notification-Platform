@echo off
setlocal

echo Running k6 load test: 8 events/sec for 60 seconds (about 480 events/minute)...
docker compose --profile loadtest run --rm k6
set EXIT_CODE=%ERRORLEVEL%

if not "%EXIT_CODE%"=="0" (
  echo.
  echo Load test failed or one of the configured thresholds was not met.
  exit /b %EXIT_CODE%
)

echo.
echo Load test completed successfully.
echo Raw summary: load-test\results\k6-summary.json
exit /b 0
