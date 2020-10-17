<?php
namespace Muni\Module\Configuration;

$config = [
    'service_manager' => [
        'factories' => [
            'Muni\Cover\Loader' => 'Muni\Cover\LoaderFactory',
            'Muni\Content\PluginManager' => 'VuFind\ServiceManager\AbstractPluginManagerFactory',
            'Muni\Content\Covers\PluginManager' => 'VuFind\ServiceManager\AbstractPluginManagerFactory',
        ],
        'aliases' => [
            'Muni\ContentPluginManager' => 'Muni\Content\PluginManager',
            'Muni\ContentCoversPluginManager' => 'Muni\Content\Covers\PluginManager',
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
            'recorddriver' => [
                'aliases' => [
                    'solrmarc' => 'Muni\RecordDriver\SolrMarc',
                ],
                'delegators' => [
                    'Muni\RecordDriver\SolrMarc' =>
                        ['VuFind\RecordDriver\IlsAwareDelegatorFactory'],
                ],
                'factories' => [
                    'Muni\RecordDriver\SolrMarc' => 'VuFind\RecordDriver\SolrDefaultFactory',
                ],
            ],
        ],
        'recorddriver_tabs' => [
            'Muni\RecordDriver\SolrMarc' => [
                'tabs' => [
                    'Holdings' => 'HoldingsILS', 'Description' => 'Description',
                    'TOC' => 'TOC', 'UserComments' => 'UserComments',
                    'Reviews' => 'Reviews', 'Excerpt' => 'Excerpt',
                    'Preview' => 'preview',
                    'HierarchyTree' => 'HierarchyTree', 'Map' => 'Map',
                    'Details' => 'StaffViewMARC',
                ],
                'defaultTab' => null,
            ],
            'Muni\RecordDriver\DefaultRecord' => [
                'tabs' => [
                    'Holdings' => 'HoldingsILS', 'Description' => 'Description',
                    'TOC' => 'TOC', 'UserComments' => 'UserComments',
                    'Reviews' => 'Reviews', 'Excerpt' => 'Excerpt',
                    'Preview' => 'preview',
                    'HierarchyTree' => 'HierarchyTree', 'Map' => 'Map',
                    'Similar' => 'SimilarItemsCarousel',
                    'Details' => 'StaffViewArray',
                ],
                'defaultTab' => null,
                // 'backgroundLoadedTabs' => ['UserComments', 'Details']
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
