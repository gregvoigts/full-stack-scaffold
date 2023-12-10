import re   

def parse_constraint(content):
    match = re.search(
        r'CONSTRAINT (\w+)_(\w+)_fkey\n\s+FOREIGN KEY\("([^"]+)"\)\s+REFERENCES public\.(\w+)\("([^"]+)"\)\s+ON DELETE (\w+)\s+ON UPDATE (\w+)',
        content
    )

    const = {'target':match.group(0),
             'source':match.group(1),
             'fk':match.group(2),
             'ref_tab':match.group(3),
             'ref_col':match.group(4)}

def parse_column(content):
    col = {'name':content[0],
           'datatype':content[1],
           'default':None,
           'not_null':False,
           'pk': False,
           'computed': None
           }
    i = 0
    while i < content.length -1:
        if content[i].upper() == 'NOT' and content[i+1].upper() == 'NULL':
            col['not_null'] = True
            i+=1
        elif content[i].upper() == 'PRIMARY' and content[i+1].upper() == 'KEY':
            col['pk'] = True
            i+=1
        elif content[i].upper() == 'DEFAULT':
            col['default'] = content[i+1]
            i+=1
        elif content[i].upper() == 'GENERATED':
            pass
        elif content[i].upper() == 'REFERENCES':
            pass
        else:
            raise Exception(f'Unkown token in SQL:{content[i]} on column {col["name"]}')
    

sql_file = "./config/db/initDB.sql"
out_path = "./backend/src/models.py"

with open(sql_file,"r") as f:
    file = f.read()

pattern = re.compile(r'CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+public\."*(\w+)"*\s*\(([^)]+)\)', re.IGNORECASE | re.DOTALL)

tables = pattern.findall(file)


for t in tables:
    table = {'columns':[],'fk':[],'referenzes':[]}
    table["name"] = t[0]
    contents = re.split(',\n', table[1])
    for content in contents:
        content_splitted = re.split('\s+|(|)', content)
        if content_splitted[0].upper() == 'UNIQUE':
            pass
        elif content_splitted[0].upper() == 'CONSTRAINT':
            table['fk'].append(parse_constraint(content))
        elif content_splitted[0].upper() == 'PRIMARY' and content_splitted[1].upper() == 'KEY':
            table['pk'].append(parse_constraint(content_splitted))
            for col in table['columns']:
                if col['name'] in content_splitted[1]:
                    col['pk'] = True
        else:
            table['columns'].append(parse_column(content_splitted))
