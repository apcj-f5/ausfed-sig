#/bin/bash

while true; do curl -skL https://health.api.f5labs.dev -o /dev/null -w "Response time is: %{time_total}. Response code: %{http_code}\n"; sleep 0.5; done

