function applySelectivity(selector, onSuccess, opts, isAjax, isDirectories, isNotPositioned) {
	var extend = (window.jQuery || window.Zepto).extend;
	const isNotStatic = isAjax != null ? isAjax : true;
	const isDirAjax = isDirectories != null ? isDirectories : true;
	const options = opts || {};

	//debugger;
	const positionDD = function (dropdownEl, selectEl) {
    // debugger;
    var el = dropdownEl;

    // NAV --> вернул старый код, поправил позицию.
    var rect = selectEl.getBoundingClientRect();
    var offset = 0;
    var dropdownHeight = el.clientHeight;
    var openUpwards = (rect.bottom + dropdownHeight > window.innerHeight &&
                       rect.top - dropdownHeight > 0);

    // debugger;

    if (!!isDirectories) {
      offset = $(el).closest('.modal').scrollTop();
      if (offset > 0) {
        offset = offset - $(selectEl).outerHeight();
      }
    }
    extend(el.style, {
        //left: rect.left + 'px',
        top: (openUpwards ? rect.top + offset - dropdownHeight : rect.bottom) + 'px',
        width: rect.width + 'px'
    });
    if (!!!isDirectories) {
      extend(el.style, {
        left: rect.left + 'px'
      });
    }
    // <--

    let width = $(selectEl).parent().find('.selectivity-single-select').outerWidth();
    $(dropdownEl).width(width - 2);
    //
    // var offset = $(selectEl).offset(),
    // elHeight = $(dropdownEl).height(),
    // selectHeight = $(selectEl).height(),
    // bottom = $(selectEl)[0].getBoundingClientRect().top + selectHeight + elHeight;
    // // //debugger;
    // if (!!!isDirectories) {
    //   $(dropdownEl).css({
    //           left: offset.left + 'px',
    //           // top: offset.top  +selectHeight + 'px'
    //       });
    //
    // }
	};

	const makeStatic = () => {
		const itemsToSelect = $(selector).data('options') || [];
		const items = _.map(itemsToSelect, (opt) => { return JSON.parse(opt); });

		let selectivityOpts = {
			allowClear: true,
			placeholder: _.get(options, 'placeholder', ''),
			items: items,
			value: $(selector).data('value')
		};

		if (!!!isNotPositioned) {
			selectivityOpts = {
				allowClear: true,
				positionDropdown: positionDD,
				placeholder: _.get(options, 'placeholder', ''),
				items: items,
				value: $(selector).data('value')
			};
		}

		$(selector).selectivity(selectivityOpts).on('change', (e) => {
			onSuccess(e);
		});
	};

	const fetchDefault = function (url, init, queryOptions) {
		return $.ajax(url).then(function(data) {
			return {
				results: _.map(data, function(item) {
					return {
						id: item.id,
						text: item.name,
					};
				}),
				more: (data.length > queryOptions.offset + data.length)
			};
		});
	};

	const fetchDirectories = function (url, init, queryOptions) {
		return $.ajax(url).then(function(data) {
			return {
				results: _.map(data, function(item) {
					var text_field = $(selector).data('text-field') ? $(selector).data('text-field') : 'name';
					return {
						id: item.id,
						text: eval(`item.${text_field}`),
					};
				}),
				more: (data.length > queryOptions.offset + data.length)
			};
		});
	}

	const fetchFunction = isDirAjax ? fetchDirectories : fetchDefault;

	const makeAjax = () => {
		//debugger;
		var _is_readonly = $(selector).data('disabled');
		if (typeof(_is_readonly) == "undefined") {
			_is_readonly = false;
		}

		let selectivityOpts = {
			allowClear: true,
			placeholder: _.get(options, 'placeholder', ''),
			readOnly: _is_readonly,
			value: $(selector).data('value'),
			ajax: {
				url: _.get(options, 'url', ''),
				quietMillis: 250,
				params: function(term, offset) {
					return { q: term };
				},
				fetch: fetchFunction
			}
		};

		if (!!!isNotPositioned) {
			selectivityOpts = {
				allowClear: true,
				positionDropdown: positionDD,
				readOnly: _is_readonly,
				placeholder: _.get(options, 'placeholder', ''),
				value: $(selector).data('value'),
				ajax: {
					url: _.get(options, 'url', ''),
					quietMillis: 250,
					params: function(term, offset) {
						return { q: term };
					},
					fetch: fetchFunction
				}
			};
		}

		$(selector).selectivity(selectivityOpts).on('change', (e) => {
			onSuccess(e);
		});
	};

	if (isNotStatic) {
		makeAjax();
	} else {
		makeStatic();
	}
}

function getSelectivityValue(event, defaultValue) {
	const defaulted = defaultValue || null;
	return $(event.target).parent().find('.selectivity-single-selected-item').data('item-id') || defaulted;
}

function getSelectivityText(event, defaultValue) {
	const defaulted = defaultValue || null;
	return $(event.target).parent().find('.selectivity-single-selected-item').text() || defaulted;
}

function setSelectivityValue(selector, id, value) {
	$(selector).find('.selectivity-single-selected-item').data('item-id', id);
	$(selector).find('.selectivity-single-selected-item').text(value);
}
