with open("input.dat", "r") as f:
    values = [int(line.strip()) for line in f if line.strip()]

group_size = 32
for i in range(0, len(values), group_size):
    group = values[i:i + group_size]
    top4 = sorted(group, reverse=True)[:4]
    group_num = i // group_size + 1
    print(f"Group {group_num}: {top4}")
