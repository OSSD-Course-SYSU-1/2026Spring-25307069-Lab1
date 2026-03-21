# sorting.py - 冒泡排序示例（dev分支新增）
def bubble_sort(arr):
    """
    冒泡排序函数：把列表从小到大排序
    :param arr: 待排序的数字列表
    :return: 排序后的列表
    """
    n = len(arr)
    # 外层循环控制排序轮数
    for i in range(n):
        # 内层循环比较相邻元素，把大的元素往后移
        for j in range(0, n-i-1):
            if arr[j] > arr[j+1]:
                arr[j], arr[j+1] = arr[j+1], arr[j]
    return arr

# 测试代码（运行文件时会执行）
if __name__ == "__main__":
    test_list = [3, 1, 4, 1, 5, 9, 2, 6]
    print("排序前：", test_list)
    print("排序后：", bubble_sort(test_list))