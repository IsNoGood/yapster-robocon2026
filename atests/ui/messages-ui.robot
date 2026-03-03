*** Settings ***
Library           Browser

Suite Setup       Open Browser To Frontend
Suite Teardown    Close Browser

*** Variables ***
${FRONTEND_URL}   http://localhost:5173

*** Test Cases ***
Post A Message
    [Documentation]    Test posting a message and verifying it appears in the list
    [Tags]    business-value    ui    smoke
    Given I am on the Yapster homepage
    When I type "Hello from Robot Framework!" in the message input
    And I click the Yap button
    Then I should see "Hello from Robot Framework!" in the yaps list
    And the page heading should say "Yaps"

Post Multiple Messages
    [Documentation]    Test posting multiple messages and verifying order
    [Tags]    business-value    ui
    Given I am on the Yapster homepage
    When I post a message "First message from test"
    And I post a message "Second message from test"
    Then the newest message should be "Second message from test"
    And the second message should be "First message from test"

Empty Message Cannot Be Posted
    [Documentation]    Test that empty messages are prevented
    [Tags]    technical    ui
    Given I am on the Yapster homepage
    When the message input is empty
    Then the Yap button should be disabled

Message Character Limit
    [Documentation]    Test that messages cannot exceed 280 characters
    [Tags]    technical    ui
    Given I am on the Yapster homepage
    When I type a message longer than 280 characters
    Then the message should be limited to 280 characters

*** Keywords ***
Open Browser To Frontend
    New Browser    chromium    headless=true
    New Page    ${FRONTEND_URL}
    Get Title    ==    Yapster - Social Media App

I am on the Yapster homepage
    Get Title    ==    Yapster - Social Media App
    Get Element    css=h1 >> text=Yapster

I type "${text}" in the message input
    Fill Text    id=message-input    ${text}

I click the Yap button
    Click    id=yap-button
    # Wait for network activity to complete (POST request)
    Wait For Load State    networkidle    timeout=5s
    Get Property    id=message-input    value    ==    ${EMPTY}

I should see "${text}" in the message list
    ${displayed_text}=    Get Text    css=.message-text >> nth=0
    Should Contain    ${displayed_text}    ${text}

I should see "${text}" in the yaps list
    ${displayed_text}=    Get Text    css=.message-text >> nth=0
    Should Contain    ${displayed_text}    ${text}

The page heading should say "Yaps"
    ${heading}=    Get Text    css=.messages-section h2
    Should Be Equal    ${heading}    Yaps

I post a message "${text}"
    Fill Text    id=message-input    ${text}
    Click    id=yap-button
    # Wait for network activity to complete (POST request)
    Wait For Load State    networkidle    timeout=5s
    Get Property    id=message-input    value    ==    ${EMPTY}

The newest message should be "${text}"
    ${first_msg}=    Get Text    css=.message-text >> nth=0
    Should Contain    ${first_msg}    ${text}

The second message should be "${text}"
    ${second_msg}=    Get Text    css=.message-text >> nth=1
    Should Contain    ${second_msg}    ${text}

The message input is empty
    Fill Text    id=message-input    ${EMPTY}

The Yap button should be disabled
    Get Attribute    id=yap-button    disabled    ==    ${EMPTY}

I type a message longer than 280 characters
    ${long_message}=    Evaluate    "a" * 281
    Fill Text    id=message-input    ${long_message}

The message should be limited to 280 characters
    ${actual_value}=    Get Property    id=message-input    value
    ${actual_length}=    Get Length    ${actual_value}
    Should Be Equal As Numbers    ${actual_length}    280
