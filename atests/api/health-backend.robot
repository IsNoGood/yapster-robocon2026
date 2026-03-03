*** Settings ***
Library           RequestsLibrary

*** Variables ***
${BACKEND_URL}    http://localhost:3000

*** Test Cases ***
Backend Health Endpoint Returns Expected Response
    [Tags]    technical    api    smoke
    Create Session    be    ${BACKEND_URL}
    ${resp}=    GET On Session    be    /health
    Should Be Equal As Integers    ${resp.status_code}    200
    Should Be Equal As Strings     ${resp.text}    Hello from backend: ok


