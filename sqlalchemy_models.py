import re

def parse_constraint(content):
    pass

def parse_column(content):
    pass

sql_file = "./config/db/initDB.sql"
out_path = "./backend/src/models.py"

with open(sql_file,"r") as f:
    file = f.read()

pattern = re.compile(r'CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+public\."*(\w+)"*\s*\(([^)]+)\)', re.IGNORECASE | re.DOTALL)

tables = pattern.findall(file)

for table in tables:
    name = table[0]
    contents = re.split(',\n', table[1])
    for content in contents:
        content_splitted = re.split('\s+', content)
        if content_splitted[0] == 'UNIQUE':
            pass
        elif content_splitted[0] == 'CONSTRAINT':
            parse_constraint(content_splitted)
        else:
            parse_column(content_splitted)
