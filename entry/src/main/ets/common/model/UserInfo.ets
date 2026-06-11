export enum RoleType {
  STUDENT = 0,
  COUNSELOR = 1,
  SCHOOL_PSY_CENTER = 2
}

export interface UserInfoJson {
  uid: string
  account: string
  name: string
  avatar: string
  className: string
  roleType: number
  portraitData: string
}

export class UserInfo {
  uid: string = ''
  account: string = ''
  name: string = ''
  avatar: string = ''
  className: string = ''
  roleType: RoleType = RoleType.STUDENT
  portraitData: string = ''

  static fromJson(json: UserInfoJson): UserInfo {
    const info = new UserInfo()
    info.uid = json.uid || ''
    info.account = json.account || ''
    info.name = json.name || ''
    info.avatar = json.avatar || ''
    info.className = json.className || ''
    info.roleType = json.roleType || RoleType.STUDENT
    info.portraitData = json.portraitData || ''
    return info
  }

  toJson(): UserInfoJson {
    return {
      uid: this.uid,
      account: this.account,
      name: this.name,
      avatar: this.avatar,
      className: this.className,
      roleType: this.roleType,
      portraitData: this.portraitData
    }
  }
}
