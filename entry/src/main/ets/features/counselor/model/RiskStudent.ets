export interface RiskStudent {
  studentId: string
  name: string
  classId: string
  dormId: string
  riskLevel: number
  moodScore: number
  lastUpdate: string
  followUpCount: number
}

export interface ClassHeatData {
  classId: string
  className: string
  riskLevel: number
  studentCount: number
  riskRatio: number
}

export interface DormHeatData {
  dormId: string
  dormName: string
  riskLevel: number
  riskStudentIds: string[]
}
