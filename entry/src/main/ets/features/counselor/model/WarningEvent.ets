export interface WarningEvent {
  eventId: string
  studentId: string
  studentName: string
  eventType: string
  riskLevel: number
  timestamp: string
  description: string
  status: number
}

export interface TimelineNode {
  stepId: string
  stepName: string
  timestamp: string
  handler: string
  result: string
  isCompleted: boolean
  isCurrent: boolean
}
