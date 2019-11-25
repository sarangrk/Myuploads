def anti_join(left, right, **kwargs):
    """Return rows in `left` which are not present in `right`"""
    kwargs['how'] = 'left'
    kwargs['indicator'] = True
    return (
        left
        .merge(right, **kwargs)
        .query('_merge == "left_only"')
        .drop(columns='_merge')
    )
