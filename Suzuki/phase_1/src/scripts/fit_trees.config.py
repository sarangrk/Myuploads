# config オブジェクトを作成する。このオブジェクトの属性としてパラメータを設定する。
c = get_config()

# 特徴量テーブルの絞り込み対象とする症状コード
c.AdditionalFeatures.target_trouble_codes = [
    '84', '7V', '7W', '7X', '7Y', '7Z', '8A', '8B',
]
# 特徴量テーブルに含める列の名前
c.AdditionalFeatures.col_names = {
    'FTIRBaseInfo': [
        'F_ID',
        'F_SELLING_MODEL_SIGN',
        'F_FCOK',
        'F_MILEAGE',
        'F_MILEAGE_UNIT',
        'F_INFO_TRANS_NO',
        'F_INFO_FUEL',
        'F_INFO_INJECTION',
        'F_INFO_ENGINE_CHARGER',
        'F_INFO_VVT_FLG',
        'F_INFO_LEAN_BURN_FLG',
        'F_INFO_HYBRID_FLG',
        'F_INFO_DRIVE',
        'F_INFO_GEARBOX',
    ],
    'TYQ0210': [
        # 'G_CAUSAL_PARTS_NO'
    ]
}

# 特徴量のファイル名は自動的に生成されるが、指定したい場合は以下を指定する。
# c.AdditionalFeatures.out_filename =

# 目的変数とする列名
c.CommonParams.target_col = 'parts'
# 出力先のディレクトリ名(下記の設定では、このファイルと同じディレクトリに出力)
import os.path as path
c.CommonParams.out_dir = path.dirname(path.abspath(__file__))

# 目的変数を生成するタスク
# デフォルトでは 引数なしの WholePartsTable が使われる。
# 下記のコメントを外すと適当なファイルを読み込むタスク ExistingFile が使われる。
# from utils.tasks import ExistingFile
# c.MakeDecisionTreeInput.target_task_class = ExistingFile
# 目的変数を生成するタスクのパラメータ
# c.MakeDecisionTreeInput.target_params = {
#     'file_path': '/path/to/target_var_file_name.csv'
# }
# 文書ごとのトピック分布のファイル名
c.MakeDecisionTreeInput.topic_filename = 'data/interim/noise_records_rev/60topics_8436126500997881296_stop-words-path=stop_words.csv_gensim-doc_topics.csv'
# 特徴量テーブルのうち、カテゴリカルな変数の名前のリスト
c.MakeDecisionTreeInput.categorical_cols = [
    'F_SELLING_MODEL_SIGN',
    'F_INFO_TRANS_NO',
    'F_INFO_FUEL',
    'F_INFO_INJECTION',
    'F_INFO_ENGINE_CHARGER',
    'F_INFO_VVT_FLG',
    'F_INFO_LEAN_BURN_FLG',
    'F_INFO_HYBRID_FLG',
    'F_INFO_DRIVE',
    'F_INFO_GEARBOX',
]

# モデルの手法
# - dt (DecisionTree)
# - rf (RandomForest)
# の2択
c.Fit.method = 'rf'
c.Fit.model_args = {
    'n_estimators': 500,
    'class_weight': 'balanced',
    'random_state': 0,
    'max_features': .50,
    'max_depth': 7,
    'oob_score': True,
}
c.Fit.model_filename = 'rf'
# 決定木の場合の例は以下
# c.Fit.method = 'dt'
# c.Fit.task_args = {
#     'model_args': {
#         'min_samples_split': 500,
#         'min_samples_leaf': 1,
#         'class_weight': 'balanced',
#         'min_impurity_decrease': 0.001,
#         'random_state': 0
#     }
# }

