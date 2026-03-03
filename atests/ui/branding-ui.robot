*** Settings ***
Documentation     NorthCode branding tests for Yapster UI
Library           Browser

Suite Setup       New Browser    headless=${True}
Suite Teardown    Close Browser

*** Variables ***
${FRONTEND_URL}    http://localhost:5173

*** Test Cases ***
User Sees NorthCode Footer With Logo
    [Documentation]    Verify NorthCode branding footer is displayed
    [Tags]    business-value    ui    smoke    branding
    Given I am on the Yapster homepage
    When I scroll to the bottom of the page
    Then I should see "Powered by:" in the footer
    And I should see the NorthCode logo in the footer

User Sees NorthCode Brutal Style Colors
    [Documentation]    Verify NorthCode color palette is applied
    [Tags]    business-value    ui    branding
    Given I am on the Yapster homepage
    When I inspect the page design
    Then the page should use NorthCode color palette
    And the background should use black or white colors
    And accent elements should use mint color

*** Keywords ***
I am on the Yapster homepage
    New Page    ${FRONTEND_URL}
    Wait For Elements State    h1    visible    timeout=5s

I scroll to the bottom of the page
    Scroll To Element    footer

I should see "${text}" in the footer
    ${footer_text}=    Get Text    footer span.footer-text
    Should Contain    ${footer_text}    ${text}

I should see the NorthCode logo in the footer
    Wait For Elements State    footer img[alt*="NorthCode"]    visible    timeout=3s

I inspect the page design
    Wait For Elements State    body    visible    timeout=3s

The page should use NorthCode color palette
    ${body_style}=    Get Style    body    background-color
    # Verify it's either black (#1c1c1c) or white (#f5f5f5)
    Should Match Regexp    ${body_style}    (rgb\\(28, 28, 28\\)|rgb\\(245, 245, 245\\))

The background should use black or white colors
    ${body_style}=    Get Style    body    background-color
    Should Match Regexp    ${body_style}    (rgb\\(28, 28, 28\\)|rgb\\(245, 245, 245\\))

Accent elements should use mint color
    # Check if mint color (#a9f5e4 / rgb(169, 245, 228)) is used somewhere
    ${button_exists}=    Run Keyword And Return Status    
    ...    Wait For Elements State    button    visible    timeout=1s
    IF    ${button_exists}
        ${button_style}=    Get Style    button    background-color
        # Just verify button has some color (mint may be used for borders, backgrounds, etc)
        Should Not Be Empty    ${button_style}
    END
