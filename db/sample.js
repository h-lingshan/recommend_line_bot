var reserveJson = {
    'context_id': 1,
    'context_name': '映画サジェスト',
    'question': {
        'qid': 1,
        'label': '見たいものは…',
        'format': 'text',
        'body': {
            'type': 'text',
            'content': '見たいものは決まっていますか'
        },
        'choice': [
            {
                'ch_id': '1_1',
                'label': 'はい',
                'question': null,
                'finish': {
                    'type': 'text',
                    'content': 'ここから検索してね¥n https://google.co.jp',
                }
            },
            {
                'ch_id': '1_2',
                'label': 'いいえ',
                'finish': null,
                'question': {
                    'qid': '1_2',
                    'label': 'どれが…',
                    'type': 'nijibox_image_select',
                    'body': {
                        'type': 'text',
                        'content': 'どれが好き？'
                    },
                    'choice': [
                        {
                            'ch_id': '1_2_1',
                            'label': '君の名は',
                            'content': 'https://aaaaa.com/aa.png',
                            'question': null,
                            'finish': {
                                'type': 'text',
                                'content': '君の名の予約はこちらから¥n https://eiga.co.jp/reserve1'
                            }
                        },
                        {
                            'ch_id': '1_2_2',
                            'label': '君の名は2',
                            'content': 'https://aaaaa.com/aa.png',
                            'question': null,
                            'finish': {
                                'type': 'text',
                                'content': '君の名2の予約はこちらから¥n https://eiga.co.jp/reserve2'
                            }
                        },
                        {
                            'ch_id': '1_2_3',
                            'label': '君の名は3',
                            'content': 'https://aaaaa.com/aa.png',
                            'question': null,
                            'finish': {
                                'type': 'text',
                                'content': '君の名3の予約はこちらから¥n https://eiga.co.jp/reserve3'
                            }
                        },
                        {
                            'ch_id': '1_2_4',
                            'label': '君の名は4',
                            'content': 'https://aaaaa.com/aa.png',
                            'question': null,
                            'finish': {
                                'type': 'text',
                                'content': '君の名4の予約はこちらから¥n https://eiga.co.jp/reserve4'
                            }
                        },
                    ]
                }
            }
        ]
    }
}