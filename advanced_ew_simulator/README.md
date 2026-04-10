# Advanced EW Simulator

主要入口：

- 图形界面：`jammer_research_ui.py`
- CLI 研究入口：`jammer_research_main.py`
- 打包脚本：`build_exe.py`

打包输出：

- `dist/AdvancedEWSimulator/AdvancedEWSimulator.exe`

说明：

- `Jammer parameters/` 是后端计算资源，不能删除。
- `jammer_research_params.json` 会在源码模式和 exe 模式下都作为可写配置文件使用。
- `jammer_research_outputs/` 会写出研究报告和图表结果。
