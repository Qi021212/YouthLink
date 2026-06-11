// entry/src/main/ets/features/counselor/pages/NewCaseDialog.ets
import { CaseData } from '../model/CaseData';
import { CaseRepository } from '../repository/CaseRepository';

@CustomDialog
export struct NewCaseDialog {
  controller: CustomDialogController;
  @State formData: CaseData = new CaseData(); // 直接使用类实例

  validate(): boolean {
    return this.formData.studentName.trim() !== '';
  }

  build() {
    Column({ space: 15 }) {
      TextInput({ placeholder: '学生姓名' })
        .onChange(v => this.formData.studentName = v)

      Button('选择截止日期: ' + new Date(this.formData.deadline).toLocaleDateString())
        .onClick(() => {
          DatePickerDialog.show({
            onAccept: (val: DatePickerResult) => {
              if (val.year !== undefined && val.month !== undefined && val.day !== undefined) {
                this.formData.deadline = new Date(val.year, val.month, val.day).getTime();
              }
            }
          })
        })

      Button('保存').onClick(async () => {
        if (this.validate()) {
          await CaseRepository.createNewCase(this.formData);
          this.controller.close(); // 保存后关闭
        }
      })
    }.padding(20)
  }
}