#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EA-18G 干扰强度对比仿真工具
EA-18G Jam Strength Comparison Simulator

作者: AI Assistant
功能: 对比不同干扰强度下的导弹拦截成功率
特点: 同时分析3、6、9三种干扰强度设置
"""

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from typing import Dict, List, Tuple, Optional
import warnings
warnings.filterwarnings('ignore')

# 设置中文字体
plt.rcParams['font.sans-serif'] = ['SimHei', 'Microsoft YaHei']
plt.rcParams['axes.unicode_minus'] = False

class EA18GComparisonSimulator:
    """EA-18G 干扰强度对比仿真器"""
    
    def __init__(self, max_jam_values: List[float]):
        """初始化仿真参数"""
        # 导弹参数
        self.missile_speed = 500  # 导弹速度 m/s
        
        # 干扰参数
        self.max_jam_values = max_jam_values  # 最大干扰值列表
        self.missile_threshold = 100  # 导弹自爆阈值
        self.reference_distance = 9260  # 参考距离：5海里 = 9260米
        
        # 仿真参数
        self.time_slice = 2  # 时间切片（秒）
        self.num_simulations = 5000  # 每个距离的仿真次数（减少以提高速度）
        
        # 方向权重
        self.direction_weights = {
            'front': 1.0,
            'left': 0.8,
            'right': 0.8,
            'rear': 0.6
        }
    
    def calculate_jam_value(self, distance: float, direction: str, max_jam_value: float) -> float:
        """计算干扰值 - 平方反比定律"""
        if distance <= 0:
            return 0
        
        direction_weight = self.direction_weights.get(direction, 0.5)
        effective_distance = max(distance, self.reference_distance)
        jam_value = max_jam_value * (self.reference_distance / effective_distance) ** 2 * direction_weight
        
        return jam_value
    
    def simulate_single_missile(self, initial_distance: float, direction: str, max_jam_value: float) -> Dict:
        """单次导弹拦截仿真"""
        flight_time = initial_distance / self.missile_speed
        current_distance = initial_distance
        time = 0
        success = False
        success_time = 0
        jam_history = []
        
        # 时间切片循环
        while time < flight_time and current_distance > 0:
            # 计算当前干扰值
            jam_value = self.calculate_jam_value(current_distance, direction, max_jam_value)
            
            # 记录干扰历史
            jam_history.append({
                'time': time,
                'distance': current_distance,
                'distance_nm': current_distance / 1852,
                'jam_value': jam_value
            })
            
            # 进行自爆判定
            explosion_probability = jam_value / self.missile_threshold
            if np.random.random() < explosion_probability:
                success = True
                success_time = time
                break
            
            # 更新导弹位置
            time += self.time_slice
            current_distance = initial_distance - self.missile_speed * time
        
        return {
            'success': success,
            'success_time': success_time,
            'final_distance': current_distance,
            'flight_time': flight_time,
            'jam_history': jam_history
        }
    
    def run_comparison_analysis(self, distances: List[float], direction: str) -> Dict:
        """运行对比分析"""
        print(f"开始干扰强度对比分析...")
        print(f"测试距离: {[d/1852 for d in distances]}海里")
        print(f"干扰方向: {direction}")
        print(f"每个距离仿真次数: {self.num_simulations}")
        print(f"对比干扰强度: {self.max_jam_values}")
        
        results = {}
        
        for jam_strength in self.max_jam_values:
            print(f"\n正在分析干扰强度 {jam_strength}...")
            jam_results = {}
            
            for i, distance in enumerate(distances):
                print(f"  距离 {i+1}/{len(distances)}: {distance/1852:.1f}海里")
                
                # 运行仿真
                simulation_results = []
                
                for j in range(self.num_simulations):
                    if (j + 1) % 1000 == 0:
                        print(f"    进度: {j + 1}/{self.num_simulations}")
                    
                    result = self.simulate_single_missile(distance, direction, jam_strength)
                    simulation_results.append(result)
                
                # 统计结果
                success_count = sum(1 for r in simulation_results if r['success'])
                success_probability = success_count / self.num_simulations
                hit_probability = 1 - success_probability
                
                jam_results[distance] = {
                    'distance_nm': distance / 1852,
                    'simulation_results': simulation_results,
                    'success_count': success_count,
                    'success_probability': success_probability,
                    'hit_probability': hit_probability,
                    'total_simulations': self.num_simulations
                }
            
            results[jam_strength] = jam_results
        
        return results
    
    def plot_comparison_analysis(self, comparison_results: Dict, save_path: str = None):
        """绘制对比分析图"""
        fig, axes = plt.subplots(2, 2, figsize=(20, 16))
        
        # 准备数据
        colors = ['red', 'blue', 'green']
        markers = ['o', 's', '^']
        
        # 1. 拦截成功概率对比
        ax1 = axes[0, 0]
        for i, (jam_strength, jam_results) in enumerate(comparison_results.items()):
            distances = [result['distance_nm'] for result in jam_results.values()]
            success_probs = [result['success_probability'] for result in jam_results.values()]
            
            ax1.plot(distances, success_probs, 
                    color=colors[i], marker=markers[i], linewidth=3, markersize=6,
                    label=f'干扰强度 {jam_strength}')
        
        ax1.set_xlabel('初始距离 (海里)', fontsize=14)
        ax1.set_ylabel('拦截成功概率', fontsize=14)
        ax1.set_title('不同干扰强度下的导弹拦截成功概率对比', fontsize=16, fontweight='bold')
        ax1.grid(True, alpha=0.3)
        ax1.set_xlim(0, 50)
        ax1.set_ylim(0, 1)
        ax1.legend(fontsize=12)
        
        # 添加参考线
        ax1.axvline(x=5, color='black', linestyle='--', alpha=0.7, label='参考距离(5海里)')
        
        # 2. 导弹击中概率对比
        ax2 = axes[0, 1]
        for i, (jam_strength, jam_results) in enumerate(comparison_results.items()):
            distances = [result['distance_nm'] for result in jam_results.values()]
            hit_probs = [result['hit_probability'] for result in jam_results.values()]
            
            ax2.plot(distances, hit_probs, 
                    color=colors[i], marker=markers[i], linewidth=3, markersize=6,
                    label=f'干扰强度 {jam_strength}')
        
        ax2.set_xlabel('初始距离 (海里)', fontsize=14)
        ax2.set_ylabel('导弹击中概率', fontsize=14)
        ax2.set_title('不同干扰强度下的导弹击中概率对比', fontsize=16, fontweight='bold')
        ax2.grid(True, alpha=0.3)
        ax2.set_xlim(0, 50)
        ax2.set_ylim(0, 1)
        ax2.legend(fontsize=12)
        
        # 添加参考线
        ax2.axvline(x=5, color='black', linestyle='--', alpha=0.7, label='参考距离(5海里)')
        
        # 3. 近距离详细对比 (1-10海里)
        ax3 = axes[1, 0]
        for i, (jam_strength, jam_results) in enumerate(comparison_results.items()):
            distances = [result['distance_nm'] for result in jam_results.values()]
            success_probs = [result['success_probability'] for result in jam_results.values()]
            
            # 只显示1-10海里的数据
            close_distances = [d for d in distances if d <= 10]
            close_probs = [success_probs[distances.index(d)] for d in close_distances]
            
            ax3.plot(close_distances, close_probs, 
                    color=colors[i], marker=markers[i], linewidth=3, markersize=8,
                    label=f'干扰强度 {jam_strength}')
        
        ax3.set_xlabel('初始距离 (海里)', fontsize=14)
        ax3.set_ylabel('拦截成功概率', fontsize=14)
        ax3.set_title('近距离详细对比 (1-10海里)', fontsize=16, fontweight='bold')
        ax3.grid(True, alpha=0.3)
        ax3.set_xlim(0, 10)
        ax3.set_ylim(0, 1)
        ax3.legend(fontsize=12)
        
        # 添加参考线
        ax3.axvline(x=5, color='black', linestyle='--', alpha=0.7, label='参考距离(5海里)')
        
        # 4. 干扰强度效果对比表
        ax4 = axes[1, 1]
        ax4.axis('off')
        
        # 创建对比表格数据
        table_data = []
        key_distances = [1, 5, 10, 20, 30, 50]
        
        for distance in key_distances:
            row = [f'{distance}海里']
            for jam_strength in self.max_jam_values:
                # 找到最接近的距离
                jam_results = comparison_results[jam_strength]
                closest_distance = min(jam_results.keys(), 
                                     key=lambda x: abs(x/1852 - distance))
                success_prob = jam_results[closest_distance]['success_probability']
                row.append(f'{success_prob:.3f}')
            table_data.append(row)
        
        # 创建表格
        headers = ['距离'] + [f'强度{j}' for j in self.max_jam_values]
        table = ax4.table(cellText=table_data, colLabels=headers,
                         cellLoc='center', loc='center',
                         bbox=[0, 0, 1, 1])
        
        table.auto_set_font_size(False)
        table.set_fontsize(10)
        table.scale(1, 2)
        
        # 设置表格样式
        for i in range(len(headers)):
            table[(0, i)].set_facecolor('#4CAF50')
            table[(0, i)].set_text_props(weight='bold', color='white')
        
        ax4.set_title('关键距离点成功率对比表', fontsize=16, fontweight='bold', pad=20)
        
        plt.suptitle('EA-18G 干扰强度对比分析报告', fontsize=18, fontweight='bold')
        plt.tight_layout()
        
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
        
        plt.show()
    
    def print_comparison_results(self, comparison_results: Dict):
        """打印对比分析结果"""
        print(f"\n{'='*80}")
        print("EA-18G 干扰强度对比分析结果")
        print(f"{'='*80}")
        
        for jam_strength in self.max_jam_values:
            print(f"\n干扰强度 {jam_strength} 的拦截成功率:")
            print(f"{'距离(海里)':<10} {'仿真次数':<8} {'成功次数':<8} {'成功概率':<10} {'击中概率':<10}")
            print(f"{'-'*60}")
            
            jam_results = comparison_results[jam_strength]
            for distance, result in jam_results.items():
                print(f"{result['distance_nm']:<10.1f} {result['total_simulations']:<8} {result['success_count']:<8} "
                      f"{result['success_probability']:<10.3f} {result['hit_probability']:<10.3f}")
        
        # 关键距离点对比
        print(f"\n关键距离点成功率对比:")
        print(f"{'距离':<8} " + "".join([f'强度{j:<8}' for j in self.max_jam_values]))
        print(f"{'-'*40}")
        
        key_distances = [1, 5, 10, 20, 30, 50]
        for distance in key_distances:
            row = f"{distance}海里"
            for jam_strength in self.max_jam_values:
                jam_results = comparison_results[jam_strength]
                closest_distance = min(jam_results.keys(), 
                                     key=lambda x: abs(x/1852 - distance))
                success_prob = jam_results[closest_distance]['success_probability']
                row += f"{success_prob:<8.3f}"
            print(row)

def main():
    """主函数"""
    print("EA-18G 干扰强度对比仿真工具")
    print("="*60)
    
    # 设置对比参数
    max_jam_values = [4, 8, 12]  # 5海里处的干扰强度
    distances = [1852, 3704, 5556, 7408, 9260, 11112, 12964, 14816, 16668, 18520, 
                20372, 22224, 24076, 25928, 27780, 29632, 31484, 33336, 35188, 37040,
                38892, 40744, 42596, 44448, 46300, 48152, 50004, 51856, 53708, 55560,
                57412, 59264, 61116, 62968, 64820, 66672, 68524, 70376, 72228, 74080,
                75932, 77784, 79636, 81488, 83340, 85192, 87044, 88896, 90748, 92600]
    direction = 'front'
    
    # 创建对比仿真器
    simulator = EA18GComparisonSimulator(max_jam_values)
    
    # 运行对比分析
    print("开始干扰强度对比分析...")
    comparison_results = simulator.run_comparison_analysis(distances, direction)
    
    # 打印对比结果
    simulator.print_comparison_results(comparison_results)
    
    # 绘制对比分析图
    print("\n正在生成对比分析图...")
    simulator.plot_comparison_analysis(comparison_results, 'jam_strength_comparison.png')
    
    # 保存结果
    print("\n正在保存结果...")
    
    # 保存对比分析结果
    for jam_strength, jam_results in comparison_results.items():
        comparison_data = []
        for distance, result in jam_results.items():
            comparison_data.append({
                'jam_strength': jam_strength,
                'distance_nm': result['distance_nm'],
                'total_simulations': result['total_simulations'],
                'success_count': result['success_count'],
                'success_probability': result['success_probability'],
                'hit_probability': result['hit_probability']
            })
        
        comparison_df = pd.DataFrame(comparison_data)
        comparison_df.to_csv(f'jam_strength_{jam_strength}_results.csv', index=False, encoding='utf-8-sig')
    
    print(f"\n对比仿真完成！")
    print(f"各干扰强度结果已保存到: jam_strength_*_results.csv")

if __name__ == "__main__":
    main()
