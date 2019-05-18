<?php
namespace VuFindLocalTemplate\Module\Configuration;

$config = [
    'router' => [
        'recorddriver_tabs' => [
            'VuFind\RecordDriver\SolrMarc' => [
                'tabs' => [
                    'Similar' => null,
                ],
            ],
        ],
    ],
];

return $config;
