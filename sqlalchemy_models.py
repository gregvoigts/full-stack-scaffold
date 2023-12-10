import re

sql_file = ""
out_path = ""

with open(sql_file,"r") as f:
    content = f.read()

pattern = re.compile(r'CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+public\.(\w+)\s*\(([^)]+)\)', re.IGNORECASE | re.DOTALL)

tables = pattern.findall(content)

for table in tables:
    name = table.group(0)
    
