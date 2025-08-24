# Crisis Intervention Alert System

A blockchain-based emergency response system for mental health crises, enabling rapid deployment of certified crisis intervention specialists.

## Overview

This contract creates a decentralized crisis response network where certified mental health professionals can respond to emergency situations. The system tracks response times, maintains responder certifications, and provides escalation protocols for critical situations.

## Features

- **Crisis Alert Creation**: Users can create prioritized crisis alerts with encrypted location data
- **Certified Responder Network**: Trained professionals register and maintain certifications
- **Real-time Response Tracking**: Monitor response times and availability
- **Escalation Protocols**: Automated escalation for unresponded alerts
- **Privacy Protection**: Location and situation details stored as hashes
- **Performance Analytics**: Track responder effectiveness and response times

## Contract Functions

### Responder Management

- `register-responder(specializations)` - Register as crisis responder
- `certify-responder(responder)` - Certify responder (owner only)
- `toggle-responder-status()` - Toggle availability status

### Alert Management

- `create-crisis-alert(priority-level, location-hash, situation-hash)` - Create emergency alert
- `respond-to-alert(alert-id, response-type, action-taken)` - Respond to crisis alert
- `close-alert(alert-id, outcome-hash)` - Close resolved alert with outcome

### Protocol Management

- `create-escalation-protocol(priority-level, max-response-time, required-responders, escalation-contacts)` - Define escalation rules (owner only)

### Read-only Functions

- `get-crisis-alert(alert-id)` - Retrieve alert details
- `get-responder-profile(responder)` - Get responder information
- `get-alert-response(alert-id, responder)` - Get response details
- `is-responder-available(responder)` - Check responder availability
- `get-emergency-threshold()` - Get emergency response threshold

## Priority Levels

1. **Level 1**: Informational/Educational
2. **Level 2**: Mild Distress
3. **Level 3**: Moderate Risk
4. **Level 4**: High Risk/Urgent
5. **Level 5**: Immediate Danger/Emergency

## Response Workflow

1. Crisis alert created with priority level
2. Available certified responders notified
3. First responder accepts and begins intervention
4. Response tracked with timestamps and actions
5. Alert closed with outcome documentation
6. Performance metrics updated

## Certification Requirements

- Responders must be certified by contract owner
- Specializations define areas of expertise
- Active status controls availability
- Response history tracked for quality assurance

## Deployment

1. Install Clarinet CLI
2. Clone this repository
3. Run `clarinet check` to validate contract
4. Deploy using `clarinet deploy`

## Security Features

- Only certified responders can respond to alerts
- Encrypted storage of sensitive location/situation data
- Immutable response tracking for accountability
- Owner-controlled certification system

## License

MIT License