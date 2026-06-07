export class ApiResponse {
  code: number = 0
  message: string = ''
  data: Object | null = null

  get isSuccess(): boolean {
    return this.code === 200
  }

  static fromJson(json: Record<string, Object>): ApiResponse {
    const resp = new ApiResponse()
    resp.code = json['code'] as number || 0
    resp.message = json['message'] as string || ''
    resp.data = json['data'] as Object || null
    return resp
  }
}

export class AuthResult {
  authStatus: boolean = false
  accessToken: string = ''
  refreshToken: string = ''
  jumpPath: string = ''
  errorCode: number = 0
  errorMsg: string = ''
  studentName: string = ''

  static fromJson(json: Record<string, Object>): AuthResult {
    const result = new AuthResult()
    result.authStatus = (json['authStatus'] as boolean) || false
    result.accessToken = json['accessToken'] as string || ''
    result.refreshToken = json['refreshToken'] as string || ''
    result.jumpPath = json['jumpPath'] as string || ''
    result.errorCode = json['errorCode'] as number || 0
    result.errorMsg = json['errorMsg'] as string || ''
    result.studentName = json['studentName'] as string || ''
    return result
  }
}
