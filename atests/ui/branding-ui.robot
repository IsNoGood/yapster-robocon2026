*** Settings ***
Documentation     RoboCon branding tests for Yapster UI
Library           Browser

Suite Setup       New Browser    headless=${True}
Suite Teardown    Close Browser

*** Variables ***
${FRONTEND_URL}    http://localhost:5173

*** Test Cases ***
User Sees RoboCon Footer With Logo
    [Documentation]    Verify RoboCon branding footer is displayed
    [Tags]    business-value    ui    smoke    branding
    Given I am on the Yapster homepage
    When I scroll to the bottom of the page
    Then I should see "Powered by" in the footer
    And I should see the RoboCon logo in the footer

User Sees RoboCon Theme Colors
    [Documentation]    Verify RoboCon color palette is applied
    [Tags]    business-value    ui    branding
    Given I am on the Yapster homepage
    When I inspect the page design
    Then the page should use RoboCon color palette
    And the background should use RoboCon dark color
    And accent elements should use RoboCon cyan color

*** Keywords ***
I am on the Yapster homepage
    New Page    ${FRONTEND_URL}
    Wait For Elements State    h1    visible    timeout=5s

I scroll to the bottom of the page
    Scroll To Element    footer

I should see "${text}" in the footer
    ${footer_text}=    Get Text    footer span.footer-text
    Should Contain    ${footer_text}    ${text}

I should see the RoboCon logo in the footer
    Wait For Elements State    footer img[alt*="RoboCon"]    visible    timeout=3s

I inspect the page design
    Wait For Elements State    body    visible    timeout=3s

The page should use RoboCon color palette
    ${body_style}=    Get Style    body    color
    Should Not Be Empty    ${body_style}

The background should use RoboCon dark color
    ${body_style}=    Get Style    body    background-color
    Should Match Regexp    ${body_style}    rgb\(15, 23, 36\)

Accent elements should use RoboCon cyan color
    ${button_exists}=    Run Keyword And Return Status
    ...    Wait For Elements State    button    visible    timeout=1s
    IF    ${button_exists}
        ${button_style}=    Get Style    button    background-color
        Should Match Regexp    ${button_style}    rgb\(17, 216, 193\)
    END
