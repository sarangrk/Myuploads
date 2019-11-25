import luigi

parse_module = __import__('20180709-chasen-parse')

if __name__ == '__main__':
    main_task = parse_module.ChasenParseWF(frac=1.)
    luigi.build(tasks=[main_task], local_scheduler=True)
