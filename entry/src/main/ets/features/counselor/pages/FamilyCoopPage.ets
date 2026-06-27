// ============================================================
// 修改后的 FamilyCoopPage.ets
// ============================================================

import {
  FamilyCase,
  CommunicationRecord,
  CaseStatus,
  CaseStatusLabel,
  CaseStatusColor,
  ContactType,
  ContactTypeLabel,
  RiskLevelLabel,
  RiskLevelColor,
  CaseFilter,
  CreateCaseData,
  AddRecordData,
  CaseStatistics
} from '../model/FamilyCase';
import { FamilyCaseService } from '../service/FamilyCaseService';
import { promptAction } from '@kit.ArkUI';

// ============================================================
// 数据类定义
// ============================================================

class StatItemData {
  label: string = '';
  count: number = 0;
  color: string = '';
  isOverdue: boolean = false;

  constructor(label: string, count: number, color: string, isOverdue: boolean) {
    this.label = label;
    this.count = count;
    this.color = color;
    this.isOverdue = isOverdue;
  }
}

class CaseItemDisplayData {
  riskLabel: string = '';
  riskColor: string = '';
  statusLabel: string = '';
  statusColor: string = '';
  showOverdue: boolean = false;
  studentName: string = '';
  classInfo: string = '';
  dormInfo: string = '';
  contactTarget: string = '';
  updatedAt: string = '';
  nextFollowUpTime: string = '';
  caseId: string = '';

  constructor(caseItem: FamilyCase) {
    this.riskLabel = RiskLevelLabel[caseItem.riskLevel] || '绿';
    this.riskColor = RiskLevelColor[caseItem.riskLevel] || '#4CAF50';
    this.statusLabel = CaseStatusLabel[caseItem.status] || '';
    this.statusColor = CaseStatusColor[caseItem.status] || '#999999';
    this.showOverdue = caseItem.isOverdue;
    this.studentName = caseItem.studentName;
    this.classInfo = caseItem.classInfo;
    this.dormInfo = caseItem.dormInfo;
    this.contactTarget = caseItem.contactTarget;
    this.updatedAt = caseItem.updatedAt;
    this.nextFollowUpTime = caseItem.nextFollowUpTime || '';
    this.caseId = caseItem.caseId;
  }
}

class DetailInfoData {
  studentName: string = '';
  studentId: string = '';
  classInfo: string = '';
  dormInfo: string = '';
  contactTarget: string = '';
  statusLabel: string = '';
  statusColor: string = '';
  isPending: boolean = false;
  isInProgress: boolean = false;
  caseId: string = '';

  constructor(c: FamilyCase) {
    this.studentName = c.studentName;
    this.studentId = c.studentId;
    this.classInfo = c.classInfo;
    this.dormInfo = c.dormInfo;
    this.contactTarget = c.contactTarget;
    this.statusLabel = CaseStatusLabel[c.status] || '';
    this.statusColor = CaseStatusColor[c.status] || '#999999';
    this.isPending = c.status === CaseStatus.PENDING;
    this.isInProgress = c.status === CaseStatus.IN_PROGRESS;
    this.caseId = c.caseId;
  }
}

class RecordItemData {
  contactLabel: string = '';
  contactTime: string = '';
  showDuration: boolean = false;
  durationText: string = '';
  content: string = '';
  showAction: boolean = false;
  actionText: string = '';

  constructor(record: CommunicationRecord) {
    this.contactLabel = ContactTypeLabel[record.contactType] || '';
    this.contactTime = record.contactTime;
    this.showDuration = record.duration !== undefined;
    this.durationText = this.showDuration ? `时长: ${record.duration}分钟` : '';
    this.content = record.content;
    this.showAction = record.actionTaken !== undefined;
    this.actionText = this.showAction ? `行动: ${record.actionTaken}` : '';
  }
}

class CreateFormData {
  studentName: string = '';
  studentId: string = '';
  classInfo: string = '';
  dormInfo: string = '';
  contactTarget: string = '';
  riskLevel: 0 | 1 | 2 | 3 = 0;
  status: CaseStatus = CaseStatus.PENDING;
}

class RecordFormData {
  contactType: ContactType = ContactType.PHONE;
  contactTime: string = '';
  duration: string = '';
  content: string = '';
  actionTaken: string = '';
  nextFollowUpTime: string = '';
}

// ============================================================
// 默认值
// ============================================================

const DEFAULT_STATISTICS: CaseStatistics = {
  total: 0,
  pending: 0,
  inProgress: 0,
  completed: 0,
  overdue: 0
};

const DEFAULT_CREATE_FORM: CreateFormData = new CreateFormData();
const DEFAULT_RECORD_FORM: RecordFormData = new RecordFormData();

// ============================================================
// 页面组件
// ============================================================

@Entry
@Component
struct FamilyCoopPage {
  @State private cases: FamilyCase[] = [];
  @State private selectedCase: FamilyCase | null = null;
  @State private records: CommunicationRecord[] = [];
  @State private isLoading: boolean = true;
  @State private filterStatus: CaseStatus | 'all' = 'all';
  @State private searchKeyword: string = '';
  @State private showOnlyOverdue: boolean = false;
  @State private showCreateDialog: boolean = false;
  @State private showRecordDialog: boolean = false;
  @State private showDetailPanel: boolean = false;
  @State private statistics: CaseStatistics = DEFAULT_STATISTICS;
  @State private createForm: CreateFormData = DEFAULT_CREATE_FORM;
  @State private recordForm: RecordFormData = DEFAULT_RECORD_FORM;

  @State private selectedRiskLevel: number = 0;
  @State private selectedContactType: ContactType = ContactType.PHONE;

  @State private isAllActive: boolean = true;
  @State private isPendingActive: boolean = false;
  @State private isInProgressActive: boolean = false;
  @State private isCompletedActive: boolean = false;
  @State private isSuspendedActive: boolean = false;

  private service: FamilyCaseService = FamilyCaseService.getInstance();

  aboutToAppear(): void {
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.isLoading = true;
    try {
      const filter: CaseFilter = {};
      if (this.filterStatus !== 'all') {
        filter.status = this.filterStatus;
      }
      if (this.searchKeyword.trim().length > 0) {
        filter.keyword = this.searchKeyword.trim();
      }
      if (this.showOnlyOverdue) {
        filter.showOnlyOverdue = true;
      }

      const casesResult: FamilyCase[] = await this.service.getCases(filter);
      const statsResult: CaseStatistics = await this.service.getStatistics();

      this.cases = casesResult;
      this.statistics = statsResult;
    } catch (error) {
      console.error('加载数据失败:', error);
      promptAction.showToast({ message: '加载数据失败，请重试' });
    } finally {
      this.isLoading = false;
    }
  }

  private async loadCaseDetail(caseId: string): Promise<void> {
    this.isLoading = true;
    try {
      const caseItem: FamilyCase | null = await this.service.getCaseDetail(caseId);
      const recordsResult: CommunicationRecord[] = await this.service.getCommunicationRecords(caseId);

      if (caseItem !== null) {
        this.selectedCase = caseItem;
        this.records = recordsResult;
        this.showDetailPanel = true;
      }
    } catch (error) {
      console.error('加载个案详情失败:', error);
      promptAction.showToast({ message: '加载详情失败' });
    } finally {
      this.isLoading = false;
    }
  }

  // 修复：处理筛选按钮点击，立即更新UI
  private handleFilterChange(status: CaseStatus | 'all'): void {
    // 立即更新UI状态
    this.isAllActive = status === 'all';
    this.isPendingActive = status === CaseStatus.PENDING;
    this.isInProgressActive = status === CaseStatus.IN_PROGRESS;
    this.isCompletedActive = status === CaseStatus.COMPLETED;
    this.isSuspendedActive = status === CaseStatus.SUSPENDED;

    // 更新筛选状态
    this.filterStatus = status;
    // 加载数据
    this.loadData();
  }

  private async handleCreateCase(): Promise<void> {
    if (this.createForm.studentName.trim().length === 0) {
      promptAction.showToast({ message: '请输入学生姓名' });
      return;
    }
    if (this.createForm.studentId.trim().length === 0) {
      promptAction.showToast({ message: '请输入学号' });
      return;
    }
    if (this.createForm.classInfo.trim().length === 0) {
      promptAction.showToast({ message: '请输入班级信息' });
      return;
    }
    if (this.createForm.contactTarget.trim().length === 0) {
      promptAction.showToast({ message: '请输入沟通目标' });
      return;
    }

    try {
      this.createForm.riskLevel = this.selectedRiskLevel as 0 | 1 | 2 | 3;

      const data: CreateCaseData = {
        studentName: this.createForm.studentName,
        studentId: this.createForm.studentId,
        classInfo: this.createForm.classInfo,
        dormInfo: this.createForm.dormInfo,
        contactTarget: this.createForm.contactTarget,
        riskLevel: this.createForm.riskLevel,
        status: this.createForm.status
      };
      await this.service.createCase(data);
      this.createForm = DEFAULT_CREATE_FORM;
      this.selectedRiskLevel = 0;
      this.showCreateDialog = false;
      promptAction.showToast({ message: '创建成功' });
      await this.loadData();
    } catch (error) {
      console.error('创建个案失败:', error);
      promptAction.showToast({ message: '创建失败，请重试' });
    }
  }

  private async handleAddRecord(): Promise<void> {
    if (this.recordForm.contactTime.trim().length === 0) {
      promptAction.showToast({ message: '请选择沟通时间' });
      return;
    }
    if (this.recordForm.content.trim().length === 0) {
      promptAction.showToast({ message: '请输入沟通内容' });
      return;
    }
    if (this.selectedCase === null) {
      promptAction.showToast({ message: '请先选择个案' });
      return;
    }

    try {
      this.recordForm.contactType = this.selectedContactType;

      const data: AddRecordData = {
        caseId: this.selectedCase.caseId,
        studentId: this.selectedCase.studentId,
        studentName: this.selectedCase.studentName,
        contactType: this.recordForm.contactType,
        contactTime: this.recordForm.contactTime,
        content: this.recordForm.content,
        actionTaken: this.recordForm.actionTaken || undefined,
        nextFollowUpTime: this.recordForm.nextFollowUpTime || undefined
      };

      if (this.recordForm.duration.trim().length > 0) {
        const durationNum: number = parseInt(this.recordForm.duration);
        if (!isNaN(durationNum) && durationNum > 0) {
          data.duration = durationNum;
        }
      }

      await this.service.addCommunicationRecord(data);

      this.recordForm = DEFAULT_RECORD_FORM;
      this.selectedContactType = ContactType.PHONE;
      this.showRecordDialog = false;
      promptAction.showToast({ message: '记录添加成功' });

      const caseId: string = this.selectedCase.caseId;
      await this.loadCaseDetail(caseId);
      await this.loadData();
    } catch (error) {
      console.error('添加记录失败:', error);
      promptAction.showToast({ message: '添加失败，请重试' });
    }
  }

  private async handleUpdateStatus(caseId: string, status: CaseStatus): Promise<void> {
    try {
      await this.service.updateCaseStatus(caseId, status);
      promptAction.showToast({ message: '状态已更新' });
      await this.loadData();
      if (this.selectedCase !== null && this.selectedCase.caseId === caseId) {
        await this.loadCaseDetail(caseId);
      }
    } catch (error) {
      console.error('更新状态失败:', error);
      promptAction.showToast({ message: '更新失败' });
    }
  }

  // ============================================================
  // 数据准备方法
  // ============================================================

  private getCaseDisplayData(caseItem: FamilyCase): CaseItemDisplayData {
    return new CaseItemDisplayData(caseItem);
  }

  private getDetailData(): DetailInfoData {
    return new DetailInfoData(this.selectedCase!);
  }

  private getRecordDisplayData(record: CommunicationRecord): RecordItemData {
    return new RecordItemData(record);
  }

  // ============================================================
  // 时间处理辅助方法
  // ============================================================

  private getCurrentDateString(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  // ============================================================
  // build方法
  // ============================================================

  build() {
    Column() {
      // ============================================================
      // 筛选栏 - 第一行：状态筛选
      // ============================================================
      Column() {
        // 第一行：状态筛选 - 使用独立的 @State 变量
        Row() {
          Text('全部')
            .fontSize(13)
            .fontColor(this.isAllActive ? '#4A90D9' : '#666666')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(14)
            .backgroundColor(this.isAllActive ? '#E8F0FE' : 'transparent')
            .margin({ right: 4 })
            .onClick(() => {
              this.handleFilterChange('all');
            })

          Text('待沟通')
            .fontSize(13)
            .fontColor(this.isPendingActive ? '#4A90D9' : '#666666')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(14)
            .backgroundColor(this.isPendingActive ? '#E8F0FE' : 'transparent')
            .margin({ right: 4 })
            .onClick(() => {
              this.handleFilterChange(CaseStatus.PENDING);
            })

          Text('进行中')
            .fontSize(13)
            .fontColor(this.isInProgressActive ? '#4A90D9' : '#666666')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(14)
            .backgroundColor(this.isInProgressActive ? '#E8F0FE' : 'transparent')
            .margin({ right: 4 })
            .onClick(() => {
              this.handleFilterChange(CaseStatus.IN_PROGRESS);
            })

          Text('已完成')
            .fontSize(13)
            .fontColor(this.isCompletedActive ? '#4A90D9' : '#666666')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(14)
            .backgroundColor(this.isCompletedActive ? '#E8F0FE' : 'transparent')
            .margin({ right: 4 })
            .onClick(() => {
              this.handleFilterChange(CaseStatus.COMPLETED);
            })

          Text('暂停')
            .fontSize(13)
            .fontColor(this.isSuspendedActive ? '#4A90D9' : '#666666')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(14)
            .backgroundColor(this.isSuspendedActive ? '#E8F0FE' : 'transparent')
            .margin({ right: 4 })
            .onClick(() => {
              this.handleFilterChange(CaseStatus.SUSPENDED);
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 4 })

        // 第二行：搜索框 + 新建按钮
        Row() {
          TextInput({ placeholder: '搜索姓名/学号/寝室' })
            .layoutWeight(1)
            .height(36)
            .fontSize(14)
            .backgroundColor('#F5F7FA')
            .borderRadius(18)
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => {
              this.searchKeyword = value;
            })
            .onSubmit(() => {
              this.loadData();
            })

          Button('+ 新建个案')
            .height(36)
            .fontSize(14)
            .backgroundColor('#4A90D9')
            .borderRadius(18)
            .padding({ left: 16, right: 16 })
            .margin({ left: 10 })
            .onClick(() => {
              this.showCreateDialog = true;
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 12 })
      }
      .width('100%')
      .backgroundColor('#FFFFFF')

      // 列表区域
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#4A90D9')
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.cases.length === 0) {
        Column() {
          Text('📋')
            .fontSize(48)
          Text('暂无个案记录')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 12 })
          Text('点击"新建个案"创建第一条记录')
            .fontSize(13)
            .fontColor('#CCCCCC')
            .margin({ top: 4 })
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.cases, (caseItem: FamilyCase) => {
            ListItem() {
              this.CaseItem(this.getCaseDisplayData(caseItem))
            }
          }, (item: FamilyCase) => item.caseId)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, bottom: 16 })
      }

      // 详情面板
      if (this.showDetailPanel && this.selectedCase !== null) {
        this.DetailPanel()
      }

      // 新建个案对话框
      if (this.showCreateDialog) {
        this.CreateDialog()
      }

      // 添加记录对话框
      if (this.showRecordDialog) {
        this.RecordDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }

  // ============================================================
  // UI组件 - 个案卡片
  // ============================================================

  @Builder
  CaseItem(data: CaseItemDisplayData) {
    Row() {
      Column() {
        Text(data.riskLabel)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width(36)
      .height(36)
      .borderRadius(18)
      .backgroundColor(data.riskColor)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Row() {
          Text(data.studentName)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
          Text(data.classInfo)
            .fontSize(13)
            .fontColor('#999999')
            .margin({ left: 8 })
          Text(data.dormInfo)
            .fontSize(13)
            .fontColor('#999999')
            .margin({ left: 8 })
          if (data.showOverdue) {
            Text('逾期')
              .fontSize(11)
              .fontColor('#FFFFFF')
              .backgroundColor('#FF6B6B')
              .borderRadius(10)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .margin({ left: 8 })
          }
        }
        .width('100%')

        Text(data.contactTarget)
          .fontSize(14)
          .fontColor('#333333')
          .margin({ top: 4 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // 第一行：状态标签 + 更新时间
        Row() {
          Text(data.statusLabel)
            .fontSize(12)
            .fontColor(data.statusColor)
          Text(`更新: ${data.updatedAt}`)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ left: 12 })
        }
        .width('100%')
        .margin({ top: 4 })

        // 第二行：下次跟进时间
        if (data.nextFollowUpTime.length > 0) {
          Text(`下次跟进: ${data.nextFollowUpTime}`)
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
            .margin({ top: 2 })
        }
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.ic_arrow_right'))
        .width(16)
        .height(16)
        .fillColor('#CCCCCC')
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .margin({ bottom: 10 })
    .onClick(() => {
      this.loadCaseDetail(data.caseId);
    })
  }

  // ============================================================
  // UI组件 - 详情面板
  // ============================================================

  @Builder
  DetailPanel() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => {
          this.showDetailPanel = false;
        })

      Column() {
        Row() {
          Text('个案详情')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          Blank()
          Button('关闭')
            .fontSize(14)
            .backgroundColor('transparent')
            .fontColor('#999999')
            .onClick(() => {
              this.showDetailPanel = false;
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 12 })
        .border({ width: { bottom: 1 }, color: '#F0F0F0' })

        this.DetailInfo(this.getDetailData())

        Column() {
          Row() {
            Text('沟通记录')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Blank()
            Button('+ 添加记录')
              .height(30)
              .fontSize(13)
              .backgroundColor('#4A90D9')
              .borderRadius(15)
              .padding({ left: 14, right: 14 })
              .onClick(() => {
                this.showRecordDialog = true;
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 8 })

          if (this.records.length === 0) {
            Text('暂无沟通记录')
              .fontSize(14)
              .fontColor('#CCCCCC')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(20)
          } else {
            List() {
              ForEach(this.records, (record: CommunicationRecord) => {
                ListItem() {
                  this.RecordItem(this.getRecordDisplayData(record))
                }
              }, (item: CommunicationRecord) => item.recordId)
            }
            .width('100%')
            .height(250)
            .padding({ left: 16, right: 16 })
          }
        }
        .margin({ top: 8 })
        .layoutWeight(1)
      }
      .width('100%')
      .height('70%')
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 })
      .position({ x: 0, y: '30%' })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  // ============================================================
  // UI组件 - 详情信息
  // ============================================================

  @Builder
  DetailInfo(data: DetailInfoData) {
    Column() {
      Row() {
        Text(`学生: ${data.studentName}`)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
        Text(`学号: ${data.studentId}`)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ left: 16 })
        Text(`班级: ${data.classInfo}`)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ left: 16 })
        Text(`寝室: ${data.dormInfo}`)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ left: 16 })
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row() {
        Text(`沟通目标: ${data.contactTarget}`)
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Text('状态: ')
            .fontSize(14)
            .fontColor('#666666')
          Text(data.statusLabel)
            .fontSize(14)
            .fontColor(data.statusColor)
            .fontWeight(FontWeight.Medium)
        }
        .margin({ left: 12 })
        .flexShrink(0)

        if (data.isPending) {
          Button('开始跟进')
            .height(28)
            .fontSize(12)
            .backgroundColor('#4ECDC4')
            .borderRadius(14)
            .padding({ left: 12, right: 12 })
            .margin({ left: 8 })
            .onClick(() => {
              this.handleUpdateStatus(data.caseId, CaseStatus.IN_PROGRESS);
            })
        } else if (data.isInProgress) {
          Button('标记完成')
            .height(28)
            .fontSize(12)
            .backgroundColor('#95E1D3')
            .borderRadius(14)
            .padding({ left: 12, right: 12 })
            .margin({ left: 8 })
            .onClick(() => {
              this.handleUpdateStatus(data.caseId, CaseStatus.COMPLETED);
            })
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F8F9FA')
    .borderRadius(8)
    .margin({ left: 16, right: 16, top: 8 })
  }

  // ============================================================
  // UI组件 - 沟通记录项
  // ============================================================

  @Builder
  RecordItem(data: RecordItemData) {
    Row() {
      Column() {
        Text(data.contactLabel)
          .fontSize(13)
          .fontColor('#4A90D9')
          .backgroundColor('#E8F0FE')
          .borderRadius(12)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
      }
      .width(60)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Row() {
          Text(data.contactTime)
            .fontSize(13)
            .fontColor('#999999')
          if (data.showDuration) {
            Text(data.durationText)
              .fontSize(13)
              .fontColor('#999999')
              .margin({ left: 12 })
          }
        }
        .width('100%')

        Text(data.content)
          .fontSize(14)
          .fontColor('#333333')
          .margin({ top: 4 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        if (data.showAction) {
          Text(data.actionText)
            .fontSize(13)
            .fontColor('#666666')
            .margin({ top: 2 })
            .width('100%')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .border({ width: { bottom: 1 }, color: '#F0F0F0' })
  }

  // ============================================================
  // UI组件 - 新建个案对话框
  // ============================================================

  @Builder
  CreateDialog() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.4)')
        .onClick(() => {
          this.showCreateDialog = false;
        })

      Column() {
        Row() {
          Text('新建个案')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          Blank()
          Button('取消')
            .fontSize(14)
            .backgroundColor('transparent')
            .fontColor('#999999')
            .onClick(() => {
              this.showCreateDialog = false;
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })

        Column() {
          Row() {
            Text('学生姓名 *')
              .width(80)
              .fontSize(14)
            TextInput({ placeholder: '请输入学生姓名' })
              .layoutWeight(1)
              .height(36)
              .backgroundColor('#F5F7FA')
              .borderRadius(8)
              .padding({ left: 12 })
              .onChange((value: string) => {
                this.createForm.studentName = value;
              })
          }
          .width('100%')
          .margin({ bottom: 10 })

          Row() {
            Text('学号 *')
              .width(80)
              .fontSize(14)
            TextInput({ placeholder: '请输入学号' })
              .layoutWeight(1)
              .height(36)
              .backgroundColor('#F5F7FA')
              .borderRadius(8)
              .padding({ left: 12 })
              .onChange((value: string) => {
                this.createForm.studentId = value;
              })
          }
          .width('100%')
          .margin({ bottom: 10 })

          Row() {
            Text('班级 *')
              .width(80)
              .fontSize(14)
            TextInput({ placeholder: '请输入班级（如：计科2201班）' })
              .layoutWeight(1)
              .height(36)
              .backgroundColor('#F5F7FA')
              .borderRadius(8)
              .padding({ left: 12 })
              .onChange((value: string) => {
                this.createForm.classInfo = value;
              })
          }
          .width('100%')
          .margin({ bottom: 10 })

          Row() {
            Text('寝室')
              .width(80)
              .fontSize(14)
            TextInput({ placeholder: '请输入寝室号' })
              .layoutWeight(1)
              .height(36)
              .backgroundColor('#F5F7FA')
              .borderRadius(8)
              .padding({ left: 12 })
              .onChange((value: string) => {
                this.createForm.dormInfo = value;
              })
          }
          .width('100%')
          .margin({ bottom: 10 })

          Row() {
            Text('沟通目标 *')
              .width(80)
              .fontSize(14)
            TextInput({ placeholder: '请输入沟通主题/目标' })
              .layoutWeight(1)
              .height(36)
              .backgroundColor('#F5F7FA')
              .borderRadius(8)
              .padding({ left: 12 })
              .onChange((value: string) => {
                this.createForm.contactTarget = value;
              })
          }
          .width('100%')
          .margin({ bottom: 10 })

          // 风险等级选择
          Row() {
            Text('风险等级 *')
              .width(80)
              .fontSize(14)
            Row() {
              Text('绿色')
                .fontSize(13)
                .fontColor(this.selectedRiskLevel === 0 ? '#FFFFFF' : '#4CAF50')
                .backgroundColor(this.selectedRiskLevel === 0 ? '#4CAF50' : 'transparent')
                .borderRadius(12)
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .border({ width: 1, color: '#4CAF50' })
                .margin({ right: 8 })
                .onClick(() => {
                  this.selectedRiskLevel = 0;
                })

              Text('黄色')
                .fontSize(13)
                .fontColor(this.selectedRiskLevel === 1 ? '#FFFFFF' : '#FFC107')
                .backgroundColor(this.selectedRiskLevel === 1 ? '#FFC107' : 'transparent')
                .borderRadius(12)
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .border({ width: 1, color: '#FFC107' })
                .margin({ right: 8 })
                .onClick(() => {
                  this.selectedRiskLevel = 1;
                })

              Text('橙色')
                .fontSize(13)
                .fontColor(this.selectedRiskLevel === 2 ? '#FFFFFF' : '#FF9800')
                .backgroundColor(this.selectedRiskLevel === 2 ? '#FF9800' : 'transparent')
                .borderRadius(12)
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .border({ width: 1, color: '#FF9800' })
                .margin({ right: 8 })
                .onClick(() => {
                  this.selectedRiskLevel = 2;
                })

              Text('红色')
                .fontSize(13)
                .fontColor(this.selectedRiskLevel === 3 ? '#FFFFFF' : '#F44336')
                .backgroundColor(this.selectedRiskLevel === 3 ? '#F44336' : 'transparent')
                .borderRadius(12)
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .border({ width: 1, color: '#F44336' })
                .margin({ right: 8 })
                .onClick(() => {
                  this.selectedRiskLevel = 3;
                })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 10 })
        }
        .padding({ left: 16, right: 16 })

        Row() {
          Button('取消')
            .width(80)
            .height(36)
            .fontSize(14)
            .backgroundColor('#F0F0F0')
            .fontColor('#666666')
            .borderRadius(18)
            .onClick(() => {
              this.showCreateDialog = false;
            })

          Blank()
            .width(16)

          Button('创建')
            .width(80)
            .height(36)
            .fontSize(14)
            .backgroundColor('#4A90D9')
            .fontColor('#FFFFFF')
            .borderRadius(18)
            .onClick(() => {
              this.handleCreateCase();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
        .margin({ top: 8 })
      }
      .width('90%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .position({ x: '5%', y: '15%' })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  // ============================================================
  // UI组件 - 添加记录对话框（修改：时间改为点击按钮弹出选择器）
  // ============================================================

  @Builder
  RecordDialog() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.4)')
        .onClick(() => {
          this.showRecordDialog = false;
        })

      Column() {
        Row() {
          Text('添加沟通记录')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          Blank()
          Button('取消')
            .fontSize(14)
            .backgroundColor('transparent')
            .fontColor('#999999')
            .onClick(() => {
              this.showRecordDialog = false;
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16 })

        Column() {
          // 沟通方式选择 - 只保留电话、微信、面谈
          Row() {
            Text('沟通方式 *')
              .width(80)
              .fontSize(14)
            Row() {
              Text('电话')
                .fontSize(13)
                .fontColor(this.selectedContactType === ContactType.PHONE ? '#FFFFFF' : '#4A90D9')
                .backgroundColor(this.selectedContactType === ContactType.PHONE ? '#4A90D9' : 'transparent')
                .borderRadius(12)
                .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                .border({ width: 1, color: '#4A90D9' })
                .margin({ right: 12 })
                .onClick(() => {
                  this.selectedContactType = ContactType.PHONE;
                })

              Text('微信')
                .fontSize(13)
                .fontColor(this.selectedContactType === ContactType.WECHAT ? '#FFFFFF' : '#4A90D9')
                .backgroundColor(this.selectedContactType === ContactType.WECHAT ? '#4A90D9' : 'transparent')
                .borderRadius(12)
                .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                .border({ width: 1, color: '#4A90D9' })
                .margin({ right: 12 })
                .onClick(() => {
                  this.selectedContactType = ContactType.WECHAT;
                })

              Text('面谈')
                .fontSize(13)
                .fontColor(this.selectedContactType === ContactType.FACE_TO_FACE ? '#FFFFFF' : '#4A90D9')
                .backgroundColor(this.selectedContactType === ContactType.FACE_TO_FACE ? '#4A90D9' : 'transparent')
                .borderRadius(12)
                .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                .border({ width: 1, color: '#4A90D9' })
                .margin({ right: 12 })
                .onClick(() => {
                  this.selectedContactType = ContactType.FACE_TO_FACE;
                })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 12 })

          // 沟通时间 - 点击按钮弹出系统时间选择器
          Row() {
            Text('沟通时间 *')
              .width(80)
              .fontSize(14)
            Row() {
              // 日期选择按钮
              Button(this.recordForm.contactTime.length >= 10 ? this.recordForm.contactTime.substring(0, 10) : '选择日期')
                .fontSize(13)
                .backgroundColor('#F5F7FA')
                .fontColor('#333333')
                .height(36)
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .margin({ right: 8 })
                .onClick(() => {
                  // 使用系统DatePickerDialog
                  DatePickerDialog.show({
                    start: new Date('2020-1-1'),
                    end: new Date('2030-12-31'),
                    selected: this.parseDateFromString(this.recordForm.contactTime),
                    onAccept: (value: DatePickerResult) => {
                      const dateStr = `${value.year}-${String(value.month! + 1).padStart(2, '0')}-${String(value.day!).padStart(2, '0')}`;
                      const timePart = this.recordForm.contactTime.length > 10 ? this.recordForm.contactTime.substring(11) : '';
                      this.recordForm.contactTime = timePart ? `${dateStr} ${timePart}` : dateStr;
                    }
                  });
                })

              // 时间选择按钮
              Button(this.recordForm.contactTime.length > 10 ? this.recordForm.contactTime.substring(11) : '选择时间')
                .fontSize(13)
                .backgroundColor('#F5F7FA')
                .fontColor('#333333')
                .height(36)
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onClick(() => {
                  // 使用系统TimePickerDialog
                  TimePickerDialog.show({
                    selected: this.parseTimeFromString(this.recordForm.contactTime),
                    onAccept: (value: TimePickerResult) => {
                      const timeStr = `${String(value.hour!).padStart(2, '0')}:${String(value.minute!).padStart(2, '0')}`;
                      const datePart = this.recordForm.contactTime.length >= 10 ? this.recordForm.contactTime.substring(0, 10) : this.getCurrentDateString();
                      this.recordForm.contactTime = `${datePart} ${timeStr}`;
                    }
                  });
                })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 12 })

          Row() {
            Text('时长(分钟)')
              .width(80)
              .fontSize(14)
            TextInput({ placeholder: '请输入时长' })
              .width(100)
              .height(36)
              .backgroundColor('#F5F7FA')
              .borderRadius(8)
              .padding({ left: 12 })
              .type(InputType.Number)
              .onChange((value: string) => {
                this.recordForm.duration = value;
              })
          }
          .width('100%')
          .margin({ bottom: 12 })

          Row() {
            Text('沟通内容 *')
              .width(80)
              .fontSize(14)
            TextArea({ placeholder: '请输入沟通详细内容' })
              .layoutWeight(1)
              .height(80)
              .backgroundColor('#F5F7FA')
              .borderRadius(8)
              .padding({ left: 12 })
              .onChange((value: string) => {
                this.recordForm.content = value;
              })
          }
          .width('100%')
          .margin({ bottom: 12 })

          Row() {
            Text('采取行动')
              .width(80)
              .fontSize(14)
            TextInput({ placeholder: '请输入采取的具体行动' })
              .layoutWeight(1)
              .height(36)
              .backgroundColor('#F5F7FA')
              .borderRadius(8)
              .padding({ left: 12 })
              .onChange((value: string) => {
                this.recordForm.actionTaken = value;
              })
          }
          .width('100%')
          .margin({ bottom: 12 })

          // 下次跟进时间 - 点击按钮弹出系统时间选择器
          Row() {
            Text('下次跟进')
              .width(80)
              .fontSize(14)
            Row() {
              // 日期选择按钮
              Button(this.recordForm.nextFollowUpTime.length >= 10 ? this.recordForm.nextFollowUpTime.substring(0, 10) : '选择日期')
                .fontSize(13)
                .backgroundColor('#F5F7FA')
                .fontColor('#333333')
                .height(36)
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .margin({ right: 8 })
                .onClick(() => {
                  DatePickerDialog.show({
                    start: new Date('2020-1-1'),
                    end: new Date('2030-12-31'),
                    selected: this.parseDateFromString(this.recordForm.nextFollowUpTime),
                    onAccept: (value: DatePickerResult) => {
                      const dateStr = `${value.year}-${String(value.month! + 1).padStart(2, '0')}-${String(value.day!).padStart(2, '0')}`;
                      const timePart = this.recordForm.nextFollowUpTime.length > 10 ? this.recordForm.nextFollowUpTime.substring(11) : '';
                      this.recordForm.nextFollowUpTime = timePart ? `${dateStr} ${timePart}` : dateStr;
                    }
                  });
                })

              // 时间选择按钮
              Button(this.recordForm.nextFollowUpTime.length > 10 ? this.recordForm.nextFollowUpTime.substring(11) : '选择时间')
                .fontSize(13)
                .backgroundColor('#F5F7FA')
                .fontColor('#333333')
                .height(36)
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onClick(() => {
                  TimePickerDialog.show({
                    selected: this.parseTimeFromString(this.recordForm.nextFollowUpTime),
                    onAccept: (value: TimePickerResult) => {
                      const timeStr = `${String(value.hour!).padStart(2, '0')}:${String(value.minute!).padStart(2, '0')}`;
                      const datePart = this.recordForm.nextFollowUpTime.length >= 10 ? this.recordForm.nextFollowUpTime.substring(0, 10) : this.getCurrentDateString();
                      this.recordForm.nextFollowUpTime = `${datePart} ${timeStr}`;
                    }
                  });
                })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 12 })
        }
        .padding({ left: 16, right: 16 })

        Row() {
          Button('取消')
            .width(80)
            .height(36)
            .fontSize(14)
            .backgroundColor('#F0F0F0')
            .fontColor('#666666')
            .borderRadius(18)
            .onClick(() => {
              this.showRecordDialog = false;
            })

          Blank()
            .width(16)

          Button('保存')
            .width(80)
            .height(36)
            .fontSize(14)
            .backgroundColor('#4A90D9')
            .fontColor('#FFFFFF')
            .borderRadius(18)
            .onClick(() => {
              this.handleAddRecord();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
        .margin({ top: 8 })
      }
      .width('90%')
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .position({ x: '5%', y: '5%' })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  // ============================================================
  // 时间选择器辅助方法
  // ============================================================

  private parseDateFromString(dateStr: string): Date {
    if (dateStr.length >= 10) {
      const parts = dateStr.substring(0, 10).split('-');
      if (parts.length === 3) {
        return new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
      }
    }
    return new Date();
  }

  private parseTimeFromString(dateStr: string): Date {
    const timePart = dateStr.length > 10 ? dateStr.substring(11) : '00:00';
    const parts = timePart.split(':');
    const now = new Date();
    now.setHours(parts.length > 0 ? parseInt(parts[0]) : 0);
    now.setMinutes(parts.length > 1 ? parseInt(parts[1]) : 0);
    return now;
  }
}

export { FamilyCoopPage };