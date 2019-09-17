<?php
namespace Muni\Module\Configuration;

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
    'service_manager' => [
        'factories' => [
            'Muni\Cover\Loader' => 'VuFind\Cover\LoaderFactory',
        ],
    ],
    'vufind' => [
        'plugin_managers' => [
            'ajaxhandler' => [
                'aliases' => [
                    'getItemStatuses' => 'Muni\AjaxHandler\GetItemStatuses',
                ],
                'factories' => [
                    'Muni\AjaxHandler\GetItemStatuses' => 'VuFind\AjaxHandler\GetItemStatusesFactory',
                ],
            ],
            'content_covers' => [
                'aliases' => [
                    'obalkyknihv3' => 'Muni\Content\Covers\ObalkyKnihV3',
                ],
                'factories' => [
                    'Muni\Content\Covers\ObalkyKnihV3' => 'Zend\ServiceManager\Factory\InvokableFactory',
                ],
            ],
            'ils_driver' => [
                'aliases' => [
                    'aleph' => 'Muni\ILS\Driver\Aleph',
                ],
                'factories' => [
                    'Muni\ILS\Driver\Aleph' => 'VuFind\ILS\Driver\AlephFactory',
                ],
            ],
            'recommend' => [
                'aliases' => [
                    'authorityrecommend' => 'Muni\Recommend\AuthorityRecommend',
                ],
                'factories' => [
                    'Muni\Recommend\AuthorityRecommend' => 'Muni\Recommend\Factory::getAuthorityRecommend',
                ],
            ],
        ],
    ],
    'controllers' => [
        'factories' => [
            'Muni\Controller\CoverController' => 'Muni\Controller\CoverControllerFactory',
        ],
        'aliases' => [
            'Cover' => 'Muni\Controller\CoverController',
            'cover' => 'Muni\Controller\CoverController',
        ],
    ],
];

return $config;
