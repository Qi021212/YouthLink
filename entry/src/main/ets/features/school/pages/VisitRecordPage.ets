import { router, promptAction } from '@kit.ArkUI';
import { VisitRecordService } from '../service/VisitRecordService';
import { VisitRecord, VisitRecordListItem, VisitStatistics } from '../model/VisitRecordModel';

// ================= 工具函数 =================
function formatDateTime(d: Date): string {
  if (!d) {
    return '';
  }
  const year: string = d.getFullYear().toString();
  const month: string = (d.getMonth() + 1).toString().padStart(2, '0');
  const day: string = d.getDate().toString().padStart(2, '0');
  const hours: string = d.getHours().toString().padStart(2, '0');
  const minutes: string = d.getMinutes().toString().padStart(2, '0');
  return year + '-' + month + '-' + day + ' ' + hours + ':' + minutes;
}

function getRiskColor(riskLevel: string): string {
  if (riskLevel === '高风险') return '#EF5350';
  if (riskLevel === '中风险') return '#FFA726';
  if (riskLevel === '低风险') return '#42A5F5';
  return '#4CAF50';
}

function getRiskBgColor(riskLevel: string): string {
  if (riskLevel === '高风险') return '#FFEBEE';
  if (riskLevel === '中风险') return '#FFF3E0';
  if (riskLevel === '低风险') return '#E3F2FD';
  return '#E8F5E9';
}

// ================= Select 选项类 =================
export class SelectOption {
  value: string = '';
  icon?: string;

  constructor(value: string, icon?: string) {
    this.value = value;
    this.icon = icon;
  }
}

// ================= 页面组件 =================
@Entry
@Component
struct VisitRecordPage {
  @State records: VisitRecordListItem[] = [];
  @State filteredRecords: VisitRecordListItem[] = [];
  @State isLoading: boolean = true;
  @State searchKeyword: string = '';

  @State showFormDialog: boolean = false;
  @State isEditing: boolean = false;
  @State editingId: string = '';

  @State formStudentName: string = '';
  @State formStudentClass: string = '';
  @State formConsultationTime: Date = new Date();
  @State formDuration: string = '45';
  @State formRoom: string = '辅导室A';
  @State selectedRoomIndex: number = 0;
  @State formRiskLevel: string = '无风险';
  @State selectedRiskLevelIndex: number = 0;
  @State formSessionSummary: string = '';
  @State formTags: string = '';

  @State showDetailDialog: boolean = false;
  @State detailRecord: VisitRecord | null = null;
  @State detailHistory: VisitRecordListItem[] = [];

  private visitService: VisitRecordService = VisitRecordService.getInstance();

  private readonly rooms: string[] = ['辅导室A', '辅导室B', '辅导室C'];
  private readonly riskLevels: string[] = ['无风险', '低风险', '中风险', '高风险'];

  // 预定义的 Select 选项数组
  private roomSelectOptions: SelectOption[] = this.rooms.map((room: string): SelectOption => {
    return new SelectOption(room);
  });

  private riskLevelSelectOptions: SelectOption[] = this.riskLevels.map((level: string): SelectOption => {
    return new SelectOption(level);
  });

  async aboutToAppear(): Promise<void> {
    try {
      await this.visitService.init(getContext(this));
      await this.loadData();
    } catch (e) {
      console.error('初始化失败', JSON.stringify(e));
      this.isLoading = false;
    }
  }

  async loadData(): Promise<void> {
    this.isLoading = true;
    try {
      this.records = await this.visitService.getAllRecords();
      this.filteredRecords = this.records;
    } catch (e) {
      console.error('加载数据失败', JSON.stringify(e));
      promptAction.showToast({ message: '加载数据失败' });
    } finally {
      this.isLoading = false;
    }
  }

  async doSearch(): Promise<void> {
    if (!this.searchKeyword || this.searchKeyword.trim().length === 0) {
      this.filteredRecords = this.records;
      return;
    }
    this.filteredRecords = await this.visitService.searchRecords(this.searchKeyword);
  }

  openCreateForm(): void {
    this.isEditing = false;
    this.editingId = '';
    this.formStudentName = '';
    this.formStudentClass = '';
    this.formConsultationTime = new Date();
    this.formDuration = '45';
    this.formRoom = '辅导室A';
    this.selectedRoomIndex = 0;
    this.formRiskLevel = '无风险';
    this.selectedRiskLevelIndex = 0;
    this.formSessionSummary = '';
    this.formTags = '';
    this.showFormDialog = true;
  }

  async openEditForm(recordId: string): Promise<void> {
    const record: VisitRecord | null = await this.visitService.getRecordById(recordId);
    if (!record) {
      promptAction.showToast({ message: '记录不存在' });
      return;
    }
    this.isEditing = true;
    this.editingId = recordId;
    this.formStudentName = record.studentName;
    this.formStudentClass = record.studentClass;
    this.formConsultationTime = record.consultationTime;
    this.formDuration = record.duration.toString();
    this.formRoom = record.room;
    this.selectedRoomIndex = this.rooms.indexOf(record.room);
    this.formRiskLevel = record.riskLevel;
    this.selectedRiskLevelIndex = this.riskLevels.indexOf(record.riskLevel);
    this.formSessionSummary = record.sessionSummary;
    this.formTags = record.tags.join('、');
    this.showFormDialog = true;
  }

  async submitForm(): Promise<void> {
    if (!this.formStudentName || this.formStudentName.trim().length === 0) {
      promptAction.showToast({ message: '请输入学生姓名' });
      return;
    }
    if (!this.formSessionSummary || this.formSessionSummary.trim().length === 0) {
      promptAction.showToast({ message: '请输入会话总结' });
      return;
    }

    const tagList: string[] = this.formTags ? this.formTags.split('、').map((s: string) => s.trim()).filter((s: string) => s.length > 0) : [];

    const data: VisitRecord = new VisitRecord();
    data.studentName = this.formStudentName.trim();
    data.studentClass = this.formStudentClass.trim();
    data.consultationTime = this.formConsultationTime;
    data.duration = parseInt(this.formDuration) || 45;
    data.room = this.formRoom;
    data.riskLevel = this.formRiskLevel;
    data.sessionSummary = this.formSessionSummary.trim();
    data.tags = tagList;

    try {
      if (this.isEditing) {
        await this.visitService.updateRecord(this.editingId, data);
        promptAction.showToast({ message: '更新成功' });
      } else {
        await this.visitService.createRecord(data);
        promptAction.showToast({ message: '创建成功' });
      }
      this.showFormDialog = false;
      await this.loadData();
    } catch (e) {
      console.error('提交失败', JSON.stringify(e));
      promptAction.showToast({ message: '操作失败，请重试' });
    }
  }

  deleteRecord(recordId: string): void {
    AlertDialog.show({
      title: '删除记录',
      message: '确定要删除这条记录吗？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      confirm: {
        value: '确定',
        fontColor: '#EF5350',
        action: () => {
          this.performDelete(recordId);
        }
      },
      cancel: () => {}
    });
  }

  async performDelete(recordId: string): Promise<void> {
    try {
      await this.visitService.deleteRecord(recordId);
      await this.loadData();
      promptAction.showToast({ message: '已删除' });
    } catch (e) {
      console.error('删除失败', JSON.stringify(e));
      promptAction.showToast({ message: '删除失败' });
    }
  }

  async viewDetail(recordId: string): Promise<void> {
    const record: VisitRecord | null = await this.visitService.getRecordById(recordId);
    if (!record) {
      promptAction.showToast({ message: '记录不存在' });
      return;
    }
    this.detailRecord = record;
    this.detailHistory = await this.visitService.getStudentHistory(record.studentName, recordId);
    this.showDetailDialog = true;
  }

  getSummaryPreview(summary: string): string {
    if (!summary) {
      return '';
    }
    if (summary.length > 30) {
      return summary.substring(0, 30) + '...';
    }
    return summary;
  }

  closeFormDialog(): void {
    this.showFormDialog = false;
  }

  closeDetailDialog(): void {
    this.showDetailDialog = false;
  }

  // ================= Build =================
  build() {
    Stack() {
      Column() {
        this.TitleBar();

        if (this.isLoading) {
          Column() {
            LoadingProgress().width(40).height(40).color('#4CAF50')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          this.SearchBar();
          this.RecordList();
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      if (this.showFormDialog) {
        this.FormDialog()
      }

      if (this.showDetailDialog) {
        this.DetailDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  // ================= 标题栏 =================
  @Builder
  TitleBar() {
    Row() {
      Button({ type: ButtonType.Normal }) {
        Image($r('app.media.back')).width(24).height(24)
      }
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        router.back();
      })

      Text('来访记录')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Button('新增')
        .fontSize(14)
        .height(32)
        .backgroundColor('#4CAF50')
        .fontColor('#FFFFFF')
        .borderRadius(16)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.openCreateForm();
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
  }


  @Builder
  StatItem(label: string, value: string, color: string) {
    Column({ space: 2 }) {
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(11)
        .fontColor('#999999')
    }
    .width('25%')
    .alignItems(HorizontalAlign.Center)
  }

  // ================= 搜索栏 =================
  @Builder
  SearchBar() {
    Row({ space: 8 }) {
      TextInput({ placeholder: '搜索姓名、班级...', text: this.searchKeyword })
        .fontSize(14)
        .height(40)
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.searchKeyword = value;
          this.doSearch();
        })

      Button('搜索')
        .fontSize(14)
        .height(40)
        .backgroundColor('#4CAF50')
        .fontColor('#FFFFFF')
        .borderRadius(8)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          this.doSearch();
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .margin({ top: 8 })
  }

  // ================= 记录列表 =================
  @Builder
  RecordList() {
    Column() {
      if (this.filteredRecords.length === 0) {
        Column() {
          Text('暂无记录')
            .fontSize(14)
            .fontColor('#999999')
            .padding(20)
        }
        .width('100%')
        .margin({ top: 20 })
      } else {
        Text('共 ' + this.filteredRecords.length + ' 条记录')
          .fontSize(12)
          .fontColor('#999999')
          .alignSelf(ItemAlign.Start)
          .padding({ left: 4, bottom: 8 })

        List({ space: 8 }) {
          ForEach(this.filteredRecords, (item: VisitRecordListItem) => {
            ListItem() {
              this.RecordItem(item)
            }
            .swipeAction({ end: this.DeleteSwipeAction(item) })
          }, (item: VisitRecordListItem) => {
            return item.id;
          })
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#1A000000' })
    .margin({ top: 8 })
    .layoutWeight(1)
  }

  // ================= 记录项 =================
  @Builder
  RecordItem(item: VisitRecordListItem) {
    Row({ space: 8 }) {
      Column()
        .width(4)
        .height(40)
        .backgroundColor(getRiskColor(item.riskLevel))
        .borderRadius(2)

      Column({ space: 2 }) {
        Row() {
          Text(item.studentName)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          Text(item.studentClass)
            .fontSize(12)
            .fontColor('#666666')
            .margin({ left: 6 })
        }
        .alignSelf(ItemAlign.Start)

        Row({ space: 6 }) {
          Text(item.room)
            .fontSize(11)
            .fontColor('#999999')
          Text('·')
            .fontSize(11)
            .fontColor('#999999')
          Text(formatDateTime(item.consultationTime))
            .fontSize(11)
            .fontColor('#999999')
          Text('·')
            .fontSize(11)
            .fontColor('#999999')
          Text(item.duration + '分钟')
            .fontSize(11)
            .fontColor('#999999')
        }
        .alignSelf(ItemAlign.Start)

        Text(this.getSummaryPreview(item.sessionSummary))
          .fontSize(12)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (item.tags && item.tags.length > 0) {
          Row({ space: 4 }) {
            ForEach(item.tags, (tag: string) => {
              Text('#' + tag)
                .fontSize(10)
                .fontColor('#4CAF50')
                .backgroundColor('#E8F5E9')
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(10)
            }, (tag: string) => {
              return tag;
            })
          }
          .alignSelf(ItemAlign.Start)
          .margin({ top: 2 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column({ space: 4 }) {
        Text(item.riskLevel)
          .fontSize(11)
          .fontColor(getRiskColor(item.riskLevel))
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(10)
          .backgroundColor(getRiskBgColor(item.riskLevel))

        Button('详情')
          .fontSize(10)
          .height(24)
          .backgroundColor('#EEEEEE')
          .fontColor('#333333')
          .borderRadius(12)
          .padding({ left: 10, right: 10 })
          .onClick(() => {
            this.viewDetail(item.id);
          })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FAFAFA')
    .borderRadius(8)
  }

  // ================= 左滑删除 =================
  @Builder
  DeleteSwipeAction(item: VisitRecordListItem) {
    Row() {
      Button('删除')
        .width(80)
        .height('100%')
        .backgroundColor('#EF5350')
        .fontColor('#FFFFFF')
        .fontSize(14)
        .borderRadius(0)
        .onClick(() => {
          this.deleteRecord(item.id);
        })
    }
    .width(80)
    .height('100%')
  }

  // ================= 表单弹窗 =================
  @Builder
  FormDialog() {
    Column() {
      Column() {
        // 标题栏
        Row() {
          Text(this.isEditing ? '编辑记录' : '新增记录')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)

          Button({ type: ButtonType.Normal }) {
            Text('✕')
              .fontSize(20)
              .fontColor('#999999')
          }
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.closeFormDialog();
          })
        }
        .width('100%')
        .padding({ bottom: 12 })
        .border({
          width: { bottom: 1 },
          color: '#EEEEEE'
        })

        // 滚动内容
        Scroll() {
          Column({ space: 14 }) {
            // 学生姓名
            Column({ space: 4 }) {
              Text('学生姓名')
                .fontSize(13)
                .fontColor('#666666')
                .alignSelf(ItemAlign.Start)
              TextInput({ placeholder: '请输入学生姓名', text: this.formStudentName })
                .fontSize(14)
                .width('100%')
                .height(40)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => {
                  this.formStudentName = value;
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // 班级
            Column({ space: 4 }) {
              Text('班级')
                .fontSize(13)
                .fontColor('#666666')
                .alignSelf(ItemAlign.Start)
              TextInput({ placeholder: '请输入班级', text: this.formStudentClass })
                .fontSize(14)
                .width('100%')
                .height(40)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => {
                  this.formStudentClass = value;
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // 日期选择
            Column({ space: 4 }) {
              Text('咨询日期')
                .fontSize(13)
                .fontColor('#666666')
                .alignSelf(ItemAlign.Start)
              Row() {
                Text(formatDateTime(this.formConsultationTime))
                  .fontSize(14)
                  .fontColor('#333333')
                  .layoutWeight(1)
                Button('选择日期')
                  .fontSize(12)
                  .height(32)
                  .backgroundColor('#4CAF50')
                  .fontColor('#FFFFFF')
                  .borderRadius(8)
                  .padding({ left: 12, right: 12 })
                  .onClick(() => {
                    const datePickerParams: DatePickerDialogOptions = {
                      start: new Date(2020, 0, 1),
                      end: new Date(2030, 11, 31),
                      selected: this.formConsultationTime,
                      onAccept: (value: DatePickerResult) => {
                        if (value.year !== undefined && value.month !== undefined && value.day !== undefined) {
                          this.formConsultationTime = new Date(value.year, value.month, value.day);
                        }
                      }
                    };
                    DatePickerDialog.show(datePickerParams);
                  })
              }
              .width('100%')
              .height(40)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
              .padding({ left: 12, right: 8 })
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // 时长 + 咨询室
            Row({ space: 12 }) {
              Column({ space: 4 }) {
                Text('时长(分钟)')
                  .fontSize(13)
                  .fontColor('#666666')
                  .alignSelf(ItemAlign.Start)
                TextInput({ placeholder: '45', text: this.formDuration })
                  .fontSize(14)
                  .width('100%')
                  .height(40)
                  .backgroundColor('#F5F5F5')
                  .borderRadius(8)
                  .padding({ left: 12, right: 12 })
                  .type(InputType.Number)
                  .onChange((value: string) => {
                    this.formDuration = value;
                  })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Column({ space: 4 }) {
                Text('咨询室')
                  .fontSize(13)
                  .fontColor('#666666')
                  .alignSelf(ItemAlign.Start)
                Select(this.roomSelectOptions)
                  .selected(this.selectedRoomIndex)
                  .value(this.formRoom)
                  .width('100%')
                  .height(40)
                  .font({ size: 14 })
                  .backgroundColor('#F5F5F5')
                  .borderRadius(8)
                  .onSelect((index: number, value?: string) => {
                    if (index >= 0 && index < this.rooms.length) {
                      this.selectedRoomIndex = index;
                      this.formRoom = this.rooms[index];
                    }
                  })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')

            // 风险等级
            Column({ space: 4 }) {
              Text('风险等级')
                .fontSize(13)
                .fontColor('#666666')
                .alignSelf(ItemAlign.Start)
              Select(this.riskLevelSelectOptions)
                .selected(this.selectedRiskLevelIndex)
                .value(this.formRiskLevel)
                .width('100%')
                .height(40)
                .font({ size: 14 })
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .onSelect((index: number, value?: string) => {
                  if (index >= 0 && index < this.riskLevels.length) {
                    this.selectedRiskLevelIndex = index;
                    this.formRiskLevel = this.riskLevels[index];
                  }
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // 会话总结
            Column({ space: 4 }) {
              Text('会话总结')
                .fontSize(13)
                .fontColor('#666666')
                .alignSelf(ItemAlign.Start)
              TextArea({ placeholder: '请输入会话总结...', text: this.formSessionSummary })
                .fontSize(14)
                .width('100%')
                .height(80)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => {
                  this.formSessionSummary = value;
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // 标签
            Column({ space: 4 }) {
              Text('标签（用顿号分隔）')
                .fontSize(13)
                .fontColor('#666666')
                .alignSelf(ItemAlign.Start)
              TextInput({ placeholder: '焦虑、失眠、考试压力', text: this.formTags })
                .fontSize(14)
                .width('100%')
                .height(40)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .padding({ left: 12, right: 12 })
                .onChange((value: string) => {
                  this.formTags = value;
                })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            Blank().height(4)
          }
          .width('100%')
          .padding({ top: 12, bottom: 8 })
        }
        .scrollBar(BarState.Auto)
        .width('100%')
        .layoutWeight(1)

        // 按钮区域 - 固定在底部
        Row({ space: 12 }) {
          Button('取消')
            .fontSize(14)
            .height(44)
            .layoutWeight(1)
            .backgroundColor('#F5F5F5')
            .fontColor('#666666')
            .borderRadius(8)
            .onClick(() => {
              this.closeFormDialog();
            })

          Button(this.isEditing ? '更新' : '保存')
            .fontSize(14)
            .height(44)
            .layoutWeight(1)
            .backgroundColor('#4CAF50')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .onClick(() => {
              this.submitForm();
            })
        }
        .width('100%')
        .padding({ top: 12 })
        .border({
          width: { top: 1 },
          color: '#EEEEEE'
        })
      }
      .width('88%')
      .constraintSize({ maxHeight: '85%' })
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0,0,0,0.5)')
    .onClick(() => {
      // 点击遮罩层不关闭，防止误操作
    })
  }

  // ================= 详情弹窗 =================
  @Builder
  DetailDialog() {
    Column() {
      Column() {
        // 标题栏
        Row() {
          Text('来访记录详情')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)

          Button({ type: ButtonType.Normal }) {
            Text('✕')
              .fontSize(20)
              .fontColor('#999999')
          }
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.closeDetailDialog();
          })
        }
        .width('100%')
        .padding({ bottom: 12 })
        .border({
          width: { bottom: 1 },
          color: '#EEEEEE'
        })

        Scroll() {
          Column({ space: 10 }) {
            // 基本信息
            Column({ space: 6 }) {
              this.DetailRow('学生', (this.detailRecord?.studentName || '') + '  ' + (this.detailRecord?.studentClass || ''))
              this.DetailRow('时间', this.detailRecord ? formatDateTime(this.detailRecord.consultationTime) : '')
              this.DetailRow('时长', this.detailRecord ? this.detailRecord.duration + ' 分钟  |  咨询室：' + this.detailRecord.room : '')
              this.DetailRow('风险等级', this.detailRecord?.riskLevel || '')
              if (this.detailRecord?.tags && this.detailRecord.tags.length > 0) {
                this.DetailRow('标签', this.detailRecord.tags.join('、'))
              }
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F8F9FA')
            .borderRadius(8)

            Divider().color('#EEEEEE')

            Column({ space: 4 }) {
              Text('会话总结')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .alignSelf(ItemAlign.Start)
              Text(this.detailRecord?.sessionSummary || '无')
                .fontSize(13)
                .fontColor('#666666')
                .alignSelf(ItemAlign.Start)
                .padding({ top: 4 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            if (this.detailHistory.length > 0) {
              Divider().color('#EEEEEE')

              Column({ space: 4 }) {
                Text('历史记录（' + this.detailHistory.length + '条）')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .alignSelf(ItemAlign.Start)

                Column({ space: 4 }) {
                  ForEach(this.detailHistory, (item: VisitRecordListItem) => {
                    Row({ space: 6 }) {
                      Text(formatDateTime(item.consultationTime))
                        .fontSize(11)
                        .fontColor('#999999')
                      Text(item.room)
                        .fontSize(11)
                        .fontColor('#999999')
                      Text(item.riskLevel)
                        .fontSize(11)
                        .fontColor(getRiskColor(item.riskLevel))
                    }
                    .width('100%')
                    .alignSelf(ItemAlign.Start)
                    .padding({ top: 2, bottom: 2 })
                  }, (item: VisitRecordListItem) => {
                    return item.id;
                  })
                }
                .width('100%')
                .padding(8)
                .backgroundColor('#F8F9FA')
                .borderRadius(8)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }

            Blank().height(4)
          }
          .width('100%')
          .padding({ top: 12, bottom: 8 })
        }
        .scrollBar(BarState.Auto)
        .width('100%')
        .layoutWeight(1)

        Button('关闭')
          .fontSize(14)
          .height(44)
          .width('100%')
          .backgroundColor('#4CAF50')
          .fontColor('#FFFFFF')
          .borderRadius(8)
          .margin({ top: 12 })
          .onClick(() => {
            this.closeDetailDialog();
          })
      }
      .width('88%')
      .constraintSize({ maxHeight: '80%' })
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0,0,0,0.5)')
    .onClick(() => {
      // 点击遮罩层不关闭，防止误操作
    })
  }

  @Builder
  DetailRow(label: string, value: string) {
    Row() {
      Text(label + '：')
        .fontSize(13)
        .fontColor('#666666')
        .width(70)
      Text(value)
        .fontSize(13)
        .fontColor('#333333')
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }
}

export default VisitRecordPage;