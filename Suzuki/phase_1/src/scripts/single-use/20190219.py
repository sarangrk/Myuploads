from math import log
import networkx
import matplotlib.pyplot as plt

from modeling.mine_subtrees import draw_from_start_3nodes


features = ['F_SELLING_MODEL_SIGN=MH55S: Y', 'F_MILEAGE: N']
target = '17540 - テンシヨナアツシ,ジエネレ-タベルトアツパ'


pos = networkx.spring_layout(g)
networkx.draw_networkx_edges(g, pos)


networkx.draw_shell(g, with_labels=True)
plt.show()

pos = networkx.drawing.nx_agraph.write_dot(g, 'graph_.dot')
networkx.draw(g, pos, with_labels=True)
plt.show()

######
import subprocess


for start in df_patterns.node1:
    start_rep = start.replace(': ', '_')
    path = f'graphs/{start_rep}.dot'
    out_path = path.split('.')[0] + '.pdf'
    g = draw_from_start_3nodes(df_patterns, start, 3, label_dict, 10)
    networkx.drawing.nx_agraph.write_dot(g, path)
    subprocess.call(f'dot {path} -T pdf -o {out_path}'.split(' '))
