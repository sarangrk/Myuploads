import pandas as pd
import pascal_voc_writer
from pascal_voc_writer import Writer
import os

## csv should consists of following column
## filename
## xmin
## xmax
## ymin
## ymax
## Class_ID
def sumee():
    print('bhiiii')
    
def voc_write():
    from_dir_list = []
    with open('pathlocation.txt') as f:
        from_dir_lines = f.readlines()

    for i in from_dir_lines:
        from_dir_list.append(i.split('=')[1][:-1])

    emtd = pd.read_csv(from_dir_list[3])

    new_emtd = emtd.sort_values(
       by='filename').reset_index().drop(['index'], axis=1)

    count_df = new_emtd.groupby('filename').size().reset_index(name='counts')

    path = os.getcwd()
    for index, row in count_df.iterrows():
       filename = row['filename']
       object_count = row['counts']
       filepath = path +'/keras_yolo3_master_final_1/EMTD/Detection/' +filename
       temp_dataframe = new_emtd[emtd.filename == filename]
       writer = Writer(filepath, 416, 416, 3)
       for temp_index, temp_row in temp_dataframe.iterrows():
           writer.addObject(temp_row['Class_ID'], temp_row['xmin'],
                            temp_row['ymin'], temp_row['xmax'], temp_row['ymax'])
       xml_file_name = filename.split('.')[0] + '.xml'
       save_file_full_path = path +'/keras_yolo3_master_final_1/EMTD/annotated_xml/' + xml_file_name
       writer.save(save_file_full_path)
