// features/counselor/pages/RiskListPage.ets

import { router } from '@kit.ArkUI';
import { CounselorService, ClassDetailResult } from '../service/CounselorService';
import {
  RiskStudent,
  RiskFilterParams,
  RiskLevel,
  RiskLevelOption,
  DormInfo,
  ClassInfo,
  getRiskLevelLabel,
  getRiskLevelColor,
  getRiskLevelBgColor,
  RISK_LEVEL_OPTIONS
} from '../model/RiskStudent';

// 定义班级选项（包含"全部"）
class ClassOption {
  value: string
  label: string

  constructor(value: string, label: string) {
    this.value = value
    this.label = label
  }
}

// 定义宿舍选项（包含"全部"）
class DormOption {
  value: string
  label: string

  constructor(value: string, label: string) {
    this.value = value
    this.label = label
  }
}

@Entry
@Component
struct RiskListPage {
  // ===== 状态变量 =====
  @State students: RiskStudent[] = [];
  @State filteredStudents: RiskStudent[] = [];
  @State isLoading: boolean = true;
  @State errorMsg: string = '';

  @State selectedRiskLevel: RiskLevel | string = 'all';
  @State selectedClassId: string = 'all';
  @State selectedDormId: string = 'all';

  @State classOptions: ClassOption[] = [];
  @State dormOptions: DormOption[] = [];
  @State filteredDormOptions: DormOption[] = [];

  @State isProfileDialogOpen: boolean = false;
  @State selectedStudent: RiskStudent | null = null;
  @State isFilterExpanded: boolean = false;

  // 用于强制刷新UI
  @State refreshKey: number = 0;
  @State filterRefreshKey: number = 0;

  // 搜索关键词
  private searchKeyword: string = '';
  private searchTimer: number | null = null;
  private counselorService: CounselorService = new CounselorService();

  // ===== 生命周期 =====
  aboutToAppear(): void {
    this.loadInitialData();
  }

  // ===== 数据加载 =====
  async loadInitialData(): Promise<void> {
    this.isLoading = true;
    this.errorMsg = '';

    try {
      const heatmapData = await this.counselorService.fetchHeatmapData();

      // 构建班级选项（包含"全部"）
      const classOptions: ClassOption[] = [];
      classOptions.push(new ClassOption('all', '全部'));
      for (let i = 0; i < heatmapData.length; i++) {
        classOptions.push(new ClassOption(heatmapData[i].classId, heatmapData[i].className));
      }
      this.classOptions = classOptions;

      const detailPromises: Promise<ClassDetailResult>[] = [];
      for (let i = 0; i < heatmapData.length; i++) {
        detailPromises.push(this.counselorService.fetchClassDetail(heatmapData[i].classId));
      }
      const details: ClassDetailResult[] = await Promise.all(detailPromises);

      let allStudents: RiskStudent[] = [];
      const allDorms: DormInfo[] = [];

      for (let i = 0; i < details.length; i++) {
        const detail = details[i];
        const classId = heatmapData[i].classId;

        for (let j = 0; j < detail.riskStudents.length; j++) {
          allStudents.push(detail.riskStudents[j]);
        }

        for (let j = 0; j < detail.dormList.length; j++) {
          const dorm = detail.dormList[j];
          allDorms.push({
            dormId: dorm.dormId,
            dormName: dorm.dormName,
            classId: classId
          });
        }
      }

      this.students = allStudents;
      this.filteredStudents = allStudents;

      // 构建宿舍选项（包含"全部"）
      const dormOptions: DormOption[] = [];
      dormOptions.push(new DormOption('all', '全部'));
      for (let i = 0; i < allDorms.length; i++) {
        dormOptions.push(new DormOption(allDorms[i].dormId, allDorms[i].dormName));
      }
      this.dormOptions = dormOptions;
      this.filteredDormOptions = dormOptions;

      this.refreshKey++;
      this.filterRefreshKey++;
    } catch (error) {
      console.error('加载数据失败:', error);
      this.errorMsg = '数据加载失败，请重试';
    } finally {
      this.isLoading = false;
    }
  }

  // ===== 核心筛选方法 =====
  applyFilters(): void {
    try {
      let result: RiskStudent[] = [];

      for (let i = 0; i < this.students.length; i++) {
        result.push(this.students[i]);
      }

      if (this.selectedRiskLevel !== 'all') {
        const filtered: RiskStudent[] = [];
        for (let i = 0; i < result.length; i++) {
          if (result[i].riskLevel === this.selectedRiskLevel) {
            filtered.push(result[i]);
          }
        }
        result = filtered;
      }

      if (this.selectedClassId !== 'all') {
        const filtered: RiskStudent[] = [];
        for (let i = 0; i < result.length; i++) {
          if (result[i].classId === this.selectedClassId) {
            filtered.push(result[i]);
          }
        }
        result = filtered;
      }

      if (this.selectedDormId !== 'all') {
        const filtered: RiskStudent[] = [];
        for (let i = 0; i < result.length; i++) {
          if (result[i].dormId === this.selectedDormId) {
            filtered.push(result[i]);
          }
        }
        result = filtered;
      }

      if (this.searchKeyword !== '') {
        const keyword: string = this.searchKeyword.trim();
        const filtered: RiskStudent[] = [];
        for (let i = 0; i < result.length; i++) {
          if (result[i].name.includes(keyword) || result[i].studentId.includes(keyword)) {
            filtered.push(result[i]);
          }
        }
        result = filtered;
      }

      this.filteredStudents = result;
      this.refreshKey++;
      this.filterRefreshKey++;
    } catch (error) {
      console.error('筛选失败:', error);
      this.errorMsg = '筛选失败';
    }
  }

  // ===== 筛选逻辑 =====
  onRiskLevelChange(value: RiskLevel | string): void {
    this.selectedRiskLevel = value;
    this.applyFilters();
  }

  onClassChange(value: string): void {
    this.selectedClassId = value;
    // 切换班级时重置宿舍为"全部"
    this.selectedDormId = 'all';

    // 更新宿舍选项列表
    if (value !== 'all') {
      const filtered: DormOption[] = [];
      filtered.push(new DormOption('all', '全部'));
      // 从 dormOptions 中筛选属于该班级的宿舍
      for (let i = 0; i < this.dormOptions.length; i++) {
        const dorm = this.dormOptions[i];
        if (dorm.value !== 'all') {
          // 查找对应的宿舍是否属于该班级
          for (let j = 0; j < this.students.length; j++) {
            if (this.students[j].dormId === dorm.value && this.students[j].classId === value) {
              filtered.push(dorm);
              break;
            }
          }
        }
      }
      this.filteredDormOptions = filtered;
    } else {
      this.filteredDormOptions = this.dormOptions;
    }

    this.applyFilters();
  }

  onDormChange(value: string): void {
    this.selectedDormId = value;
    this.applyFilters();
  }

  onSearchInput(value: string): void {
    this.searchKeyword = value;

    if (this.searchTimer !== null) {
      clearTimeout(this.searchTimer);
      this.searchTimer = null;
    }

    this.searchTimer = setTimeout(() => {
      this.applyFilters();
      this.searchTimer = null;
    }, 500);
  }

  resetFilters(): void {
    this.selectedRiskLevel = 'all';
    this.selectedClassId = 'all';
    this.selectedDormId = 'all';
    this.searchKeyword = '';
    this.filteredDormOptions = this.dormOptions;
    this.applyFilters();
  }

  // ===== 学生详情弹窗 =====
  showStudentProfile(student: RiskStudent): void {
    this.selectedStudent = student;
    this.isProfileDialogOpen = true;
  }

  closeProfileDialog(): void {
    this.isProfileDialogOpen = false;
    this.selectedStudent = null;
  }

  // ===== 构建UI =====
  build(): void {
    Column() {
      this.buildHeader();
      this.buildFilterBar();

      if (this.isLoading) {
        this.buildLoadingState();
      } else if (this.errorMsg !== '') {
        this.buildErrorState();
      } else if (this.filteredStudents.length === 0) {
        this.buildEmptyState();
      } else {
        this.buildStudentList();
      }

      this.buildProfileDialog();
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }

  // ===== 构建函数 =====
  @Builder
  buildHeader(): void {
    Row() {
      Text('风险学生清单')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A2E')

      Blank()

      Text('共 ' + this.filteredStudents.length + ' 人')
        .fontSize(14)
        .fontColor('#999999')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 12 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildFilterBar(): void {
    Column() {
      // 搜索框
      Row() {
        TextInput({ placeholder: '搜索姓名或学号', text: this.searchKeyword })
          .layoutWeight(1)
          .height(36)
          .backgroundColor('transparent')
          .padding(0)
          .fontSize(14)
          .onChange((value: string) => {
            this.onSearchInput(value);
          })

        if (this.searchKeyword !== '') {
          Text('✕')
            .fontSize(16)
            .fontColor('#999999')
            .onClick(() => {
              this.searchKeyword = '';
              this.applyFilters();
            })
        }
      }
      .width('100%')
      .height(40)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#F5F6FA')
      .borderRadius(8)
      .margin({ bottom: 8 })

      // ===== 筛选栏 - 风险等级 =====
      Row() {
        Text('风险等级')
          .fontSize(13)
          .fontColor('#666666')
          .width(60)

        Scroll() {
          Row({ space: 6 }) {
            ForEach(RISK_LEVEL_OPTIONS, (option: RiskLevelOption) => {
              this.buildFilterTag(
                option.label,
                this.selectedRiskLevel === option.value,
                () => {
                  this.onRiskLevelChange(option.value);
                }
              )
            }, (option: RiskLevelOption) => 'risk_' + option.value + '_' + this.filterRefreshKey)
          }
          .padding({ left: 0, right: 0 })
        }
        .layoutWeight(1)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .padding({ top: 2, bottom: 2 })

      // ===== 筛选栏 - 班级（使用 ClassOption 列表） =====
      Row() {
        Text('班级')
          .fontSize(13)
          .fontColor('#666666')
          .width(60)

        Scroll() {
          Row({ space: 6 }) {
            ForEach(this.classOptions, (option: ClassOption) => {
              this.buildFilterTag(
                option.label,
                this.selectedClassId === option.value,
                () => {
                  this.onClassChange(option.value);
                }
              )
            }, (option: ClassOption) => 'class_' + option.value + '_' + this.filterRefreshKey)
          }
          .padding({ left: 0, right: 0 })
          .alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .align(Alignment.Start)
      }
      .width('100%')
      .padding({ top: 2, bottom: 2 })
      .alignItems(VerticalAlign.Center)

      // ===== 筛选栏 - 宿舍（展开时显示，使用 DormOption 列表） =====
      if (this.isFilterExpanded) {
        Row() {
          Text('宿舍')
            .fontSize(13)
            .fontColor('#666666')
            .width(60)

          Scroll() {
            Row({ space: 6 }) {
              ForEach(this.filteredDormOptions, (option: DormOption) => {
                this.buildFilterTag(
                  option.label,
                  this.selectedDormId === option.value,
                  () => {
                    this.onDormChange(option.value);
                  }
                )
              }, (option: DormOption) => 'dorm_' + option.value + '_' + this.filterRefreshKey)
            }
            .padding({ left: 0, right: 0 })
            .alignItems(VerticalAlign.Center)
          }
          .layoutWeight(1)
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .align(Alignment.Start)
        }
        .width('100%')
        .padding({ top: 2, bottom: 2 })
        .alignItems(VerticalAlign.Center)

        // 重置按钮
        Button('重置筛选')
          .width('100%')
          .height(32)
          .fontSize(13)
          .backgroundColor('#E8EAF6')
          .fontColor('#3F51B5')
          .borderRadius(6)
          .margin({ top: 8 })
          .onClick(() => {
            this.resetFilters();
          })
      }

      // 展开/收起
      Row() {
        Text(this.isFilterExpanded ? '收起筛选 ▲' : '展开筛选 ▼')
          .fontSize(12)
          .fontColor('#3F51B5')
          .onClick(() => {
            this.isFilterExpanded = !this.isFilterExpanded;
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .padding({ top: 6 })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor('#FFFFFF')
    .margin({ bottom: 6 })
  }

  @Builder
  buildFilterTag(label: string, isSelected: boolean, onClick: () => void): void {
    Text(label)
      .fontSize(12)
      .fontColor(isSelected ? '#FFFFFF' : '#666666')
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .backgroundColor(isSelected ? '#3F51B5' : '#F5F6FA')
      .borderRadius(12)
      .height(28)
      .onClick(() => {
        onClick();
      })
  }

  @Builder
  buildStudentList(): void {
    List() {
      ForEach(this.filteredStudents, (student: RiskStudent) => {
        ListItem() {
          this.buildStudentItem(student)
        }
      }, (student: RiskStudent) => student.studentId + '_' + this.refreshKey)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 12, right: 12 })
    .listDirection(Axis.Vertical)
    .divider({
      strokeWidth: 1,
      color: '#F0F0F0',
      startMargin: 56,
      endMargin: 0
    })
  }

  @Builder
  buildStudentItem(student: RiskStudent): void {
    Row() {
      Column() {
        Text(getRiskLevelLabel(student.riskLevel))
          .fontSize(10)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
      }
      .width(44)
      .height(44)
      .backgroundColor(getRiskLevelColor(student.riskLevel))
      .borderRadius(22)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Row() {
          Text(student.name)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')

          Text(student.studentId)
            .fontSize(11)
            .fontColor('#999999')
            .margin({ left: 6 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row() {
          Text(student.gender + ' · ' + student.className)
            .fontSize(12)
            .fontColor('#666666')

          Blank()

          Text('寝室 ' + student.dormName)
            .fontSize(12)
            .fontColor('#666666')
        }
        .width('100%')
        .margin({ top: 2 })

        Row() {
          Text('情绪分: ' + student.moodScore.toFixed(1))
            .fontSize(11)
            .fontColor('#999999')

          Blank()

          Text('更新: ' + student.lastUpdate)
            .fontSize(11)
            .fontColor('#999999')
        }
        .width('100%')
        .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 })

      Column() {
        Text('›')
          .fontSize(18)
          .fontColor('#CCCCCC')
      }
      .width(30)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .onClick(() => {
      this.showStudentProfile(student);
    })
  }

  @Builder
  buildLoadingState(): void {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
        .margin({ top: 40 })

      Text('加载中...')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 12 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildErrorState(): void {
    Column() {
      Text('⚠️')
        .fontSize(40)
        .margin({ top: 40 })

      Text(this.errorMsg)
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 12 })

      Button('重试')
        .width(100)
        .height(36)
        .fontSize(13)
        .backgroundColor('#3F51B5')
        .borderRadius(8)
        .margin({ top: 16 })
        .onClick(() => {
          this.loadInitialData();
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildEmptyState(): void {
    Column() {
      Text('📭')
        .fontSize(40)
        .margin({ top: 40 })

      Text('暂无匹配的学生')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 12 })

      Text('尝试调整筛选条件')
        .fontSize(12)
        .fontColor('#CCCCCC')
        .margin({ top: 6 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // ===== 学生画像弹窗 =====
  @Builder
  buildProfileDialog(): void {
    if (this.isProfileDialogOpen && this.selectedStudent !== null) {
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.4)')
          .onClick(() => {
            this.closeProfileDialog();
          })

        Column() {
          this.buildProfileContent(this.selectedStudent as RiskStudent)
        }
        .width('85%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
    }
  }

  @Builder
  buildProfileContent(student: RiskStudent): void {
    Column() {
      Row() {
        Text('👤 学生画像')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A2E')

        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16 })

      Divider()
        .color('#F0F0F0')
        .margin({ top: 10, bottom: 10 })

      Row() {
        Column() {
          Text(student.name.charAt(0))
            .fontSize(30)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
        }
        .width(56)
        .height(56)
        .backgroundColor(getRiskLevelColor(student.riskLevel))
        .borderRadius(28)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text(student.name)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A2E')

          Row({ space: 8 }) {
            Text(student.gender)
              .fontSize(13)
              .fontColor('#666666')
            Text('|')
              .fontSize(13)
              .fontColor('#DDDDDD')
            Text(student.className)
              .fontSize(13)
              .fontColor('#666666')
          }
          .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      Column() {
        Row() {
          Column() {
            Text('风险等级')
              .fontSize(12)
              .fontColor('#999999')
            Text(getRiskLevelLabel(student.riskLevel))
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(getRiskLevelColor(student.riskLevel))
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 10, bottom: 10 })

          Divider()
            .vertical(true)
            .height(40)
            .color('#F0F0F0')

          Column() {
            Text('情绪评分')
              .fontSize(12)
              .fontColor('#999999')
            Text(student.moodScore.toFixed(1))
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#3F51B5')
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 10, bottom: 10 })
        }
        .width('100%')
        .backgroundColor(getRiskLevelBgColor(student.riskLevel))
        .borderRadius(8)
        .padding({ left: 16, right: 16 })
        .margin({ left: 16, right: 16, top: 10 })
      }

      Column() {
        this.buildDetailRow('学号', student.studentId)
        this.buildDetailRow('宿舍', student.dormName)
        this.buildDetailRow('联系方式', student.phone)
        this.buildDetailRow('最近更新', student.lastUpdate)

        if (student.riskReason !== undefined && student.riskReason !== '') {
          Column() {
            Text('📋 风险原因')
              .fontSize(13)
              .fontColor('#666666')
              .margin({ bottom: 4 })

            Text(student.riskReason)
              .fontSize(13)
              .fontColor('#333333')
              .width('100%')
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor('#FFF8E1')
              .borderRadius(6)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ top: 6, bottom: 4 })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 6 })

      Row() {
        Button('关闭')
          .width('100%')
          .height(40)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#3F51B5')
          .fontColor('#FFFFFF')
          .borderRadius(20)
          .onClick(() => {
            this.closeProfileDialog();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 16 })
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  buildDetailRow(label: string, value: string): void {
    Row() {
      Text(label + '：')
        .fontSize(13)
        .fontColor('#999999')
        .width(60)

      Text(value)
        .fontSize(13)
        .fontColor('#333333')
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }
}

export default RiskListPage;