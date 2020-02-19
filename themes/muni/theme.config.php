<?php
return [
    'extends' => 'bootstrap3',
    'helpers' => [
        'factories' => [
            'Muni\View\Helper\Muni\RecordDataFormatter' => 'Muni\View\Helper\Muni\RecordDataFormatterFactory',
        ],
        'aliases' => [
            'recordDataFormatter' => 'Muni\View\Helper\Muni\RecordDataFormatter',
        ]
    ],
    'css' => [
        'muni.css'
    ]
];
