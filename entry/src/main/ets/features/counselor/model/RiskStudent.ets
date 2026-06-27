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
  gender: 'Male' | 'Female'
  beds: number[]
}

// features/counselor/model/RiskStudent.ets

// ===== 类型定义 =====
export type RiskLevel = 0 | 1 | 2 | 3;

// ===== 接口定义 =====
export interface RiskStudent {
  studentId: string;
  name: string;
  classId: string;
  className: string;
  dormId: string;
  dormName: string;
  riskLevel: RiskLevel;
  moodScore: number;
  lastUpdate: string;
  followUpCount: number;
  phone: string;
  gender: string;
  avatar?: string;
  riskReason?: string;
}

export interface RiskFilterParams {
  riskLevel?: RiskLevel | string;
  dormId?: string;
  classId?: string;
  keyword?: string;
}

export interface DormInfo {
  dormId: string;
  dormName: string;
  classId: string;
}

export interface RiskLevelConfig {
  label: string;
  color: string;
  bgColor: string;
}

export interface RiskLevelOption {
  value: RiskLevel | string;
  label: string;
}

export interface ClassInfo {
  classId: string;
  className: string;
}

// ===== 常量定义 - 使用明确的类型注解，不使用as const =====
export const RISK_LEVEL_CONFIG: Record<string, RiskLevelConfig> = {
  'level0': { label: '低风险', color: '#4CAF50', bgColor: '#E8F5E9' },
  'level1': { label: '中低风险', color: '#FF9800', bgColor: '#FFF3E0' },
  'level2': { label: '中高风险', color: '#FF5722', bgColor: '#FBE9E7' },
  'level3': { label: '高风险', color: '#F44336', bgColor: '#FFEBEE' }
};

export const RISK_LEVEL_WEIGHT: Record<string, number> = {
  'level0': 0,
  'level1': 1,
  'level2': 2,
  'level3': 3
};

// 使用普通数组，明确类型注解
export const RISK_LEVEL_OPTIONS: RiskLevelOption[] = [
  { value: 'all', label: '全部' },
  { value: 0, label: '低风险' },
  { value: 1, label: '中低风险' },
  { value: 2, label: '中高风险' },
  { value: 3, label: '高风险' }
];

// ===== 工具函数 =====
export function getRiskLevelConfig(level: RiskLevel): RiskLevelConfig {
  if (level === 0) {
    return { label: '低风险', color: '#4CAF50', bgColor: '#E8F5E9' };
  } else if (level === 1) {
    return { label: '中低风险', color: '#FF9800', bgColor: '#FFF3E0' };
  } else if (level === 2) {
    return { label: '中高风险', color: '#FF5722', bgColor: '#FBE9E7' };
  } else if (level === 3) {
    return { label: '高风险', color: '#F44336', bgColor: '#FFEBEE' };
  } else {
    return { label: '未知', color: '#999999', bgColor: '#F5F5F5' };
  }
}

export function getRiskLevelLabel(level: RiskLevel): string {
  const config: RiskLevelConfig = getRiskLevelConfig(level);
  return config.label;
}

export function getRiskLevelColor(level: RiskLevel): string {
  const config: RiskLevelConfig = getRiskLevelConfig(level);
  return config.color;
}

export function getRiskLevelBgColor(level: RiskLevel): string {
  const config: RiskLevelConfig = getRiskLevelConfig(level);
  return config.bgColor;
}

export function getRiskLevelWeight(level: RiskLevel): number {
  if (level === 0) {
    return 0;
  } else if (level === 1) {
    return 1;
  } else if (level === 2) {
    return 2;
  } else if (level === 3) {
    return 3;
  } else {
    return 0;
  }
}

export function getRiskLevelOptionLabel(value: RiskLevel | string): string {
  if (value === 'all') {
    return '全部';
  } else if (value === 0) {
    return '低风险';
  } else if (value === 1) {
    return '中低风险';
  } else if (value === 2) {
    return '中高风险';
  } else if (value === 3) {
    return '高风险';
  } else {
    return '全部';
  }
}

export function isValidRiskLevel(value: number): boolean {
  return value === 0 || value === 1 || value === 2 || value === 3;
}