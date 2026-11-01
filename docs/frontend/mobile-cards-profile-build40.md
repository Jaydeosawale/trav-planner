# Mobile cards, Profile and AI composer — build 40

1 November 2026.

The Home AI invitation and Compare travel options now share an OceanActionCard component and one ocean gradient token. This keeps background, peach icon, text contrast, spacing and tap behavior consistent. Travel options retain the current destination when opening supplier links. Day-idea cards gain a gentle gradient, tinted edge and light elevation around their colorful badges.

Profile uses a compact ocean identity card with mint avatar, readable name and wrapping email. At large text sizes its identity changes to a vertical layout. Settings use smaller icons, 14px titles, compact padding, and clear Account, Travel, and Privacy & data sections. Reset password opens the existing recovery screen on the root navigator with the signed-in email prefilled. It requires the user to request the email and complete the established secure reset flow; it does not change a password directly or send unsolicited mail. Guest sign-in and logout behavior are retained.

The AI composer uses 14px text and a bounded 56px suffix area around a 48px send target. The button no longer stretches with a multiline field. Empty messages are ignored; location/request loading states and keyboard positioning remain intact.

Navigation checks cover Profile-to-recovery with the account email and a four-line phone composer with an accessible, fixed-size send target. Existing app suite and fixture screenshots cover shared card changes. Google Play publication remains on hold; no paid service or provider change.

Validation: 119 checks passed in the full suite; its remaining large-text recovery-logo overflow was fixed, then all five focused Profile/composer/auth checks passed. Analysis has no errors or warnings; existing informational lints remain. The recovery logo scales to fit a narrow phone and reset buttons can grow with text. Profile and multiline composer fixture renders were inspected at 320px. No real recovery email was sent during these checks.
