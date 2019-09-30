<?php
/**
 * ObalkyKnih V3 cover content loader.
 *
 * PHP version 7
 *
 * Copyright (C) Masaryk University 2019.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * @category VuFind
 * @package  Content
 * @author   Vit Novotny <witiko@mail.muni.cz>
 * @license  http://opensource.org/licenses/gpl-2.0.php GNU General Public License
 * @link     https://vufind.org/wiki/development Wiki
 */
namespace Muni\Content\Covers;

/**
 * ObalkyKnih V3 cover content loader.
 *
 * @category VuFind
 * @package  Content
 * @author   Vit Novotny <witiko@mail.muni.cz>
 * @license  http://opensource.org/licenses/gpl-2.0.php GNU General Public License
 * @link     https://vufind.org/wiki/development Wiki
 */
class ObalkyKnihV3 extends \VuFind\Content\AbstractCover
    implements \VuFindHttp\HttpServiceAwareInterface, \Zend\Log\LoggerAwareInterface
{
    use \VuFindHttp\HttpServiceAwareTrait;
    use \VuFind\Log\LoggerAwareTrait;

    /**
     * Constructor
     */
    public function __construct()
    {
        $this->supportsIsbn = true;
        $this->supportsIssn = true;
        $this->supportsOclc = true;
    }

    /**
     * Get an HTTP client
     *
     * @param string $url URL for client to use
     *
     * @return \Zend\Http\Client
     */
    protected function getHttpClient($url = null)
    {
        if (null === $this->httpService) {
            throw new \Exception('HTTP service missing.');
        }
        return $this->httpService->createClient($url);
    }

    /**
     * Get image URL for a particular API key and set of IDs (or false if invalid).
     *
     * @param string $key  API key
     * @param string $size Size of image to load (small/medium/large)
     * @param array  $ids  Associative array of identifiers (keys may include 'isbn'
     * pointing to an ISBN object and 'issn' pointing to a string)
     *
     * @return string|bool
     *
     * @SuppressWarnings(PHPMD.UnusedFormalParameter)
     */
    public function getUrl($key, $size, $ids)
    {
        // Implement failover
        $client = $this->httpService->createClient(
            'https://cache.obalkyknih.cz/api/runtime/alive'
        );
        $client->setMethod('GET');
        $result = $client->send();
        $answer = $result->getBody();
        if ($answer == 'ALIVE') {
            $server = 'cache.obalkyknih.cz';
        } else {
            $server = 'cache2.obalkyknih.cz';
        }

        // Use multiple identifiers
        $identifiers = array();
        if (isset($ids['isbn'])) {
            $identifiers['isbn'] = $ids['isbn']->get13();
        }
        elseif (isset($ids['issn'])) {
            $identifiers['isbn'] = $ids['issn'];
        }

        if (isset($ids['oclc'])) {
            $identifiers['oclc'] = '(OCoLC)' . $ids['oclc'];
        }

        // Construct the URL
        $queryUrl = 'https://' . $server . '/api/books?multi=';
        $queryUrl .= urlencode('[' . json_encode($identifiers) . ']');
        $queryUrl .= '&keywords=';

        // Request information from the server
        $this->debug('Querying the following ObalkyKnihV3 URL: ' . $queryUrl);
        $client = $this->httpService->createClient($queryUrl);
        $client->setMethod('GET');
        $result = $client->send();
        $answer = json_decode($result->getBody(), true);

        // Produce the URL of the thumbnail
        if (!empty($answer) and !empty($answer[0]) and isset($answer[0]['cover_medium_url'])) {
            $url = $answer[0]['cover_medium_url'];
            $this->debug('Produced the following ObalkyKnihV3 URL: ' . $url);
            return $url;
        } else {
            $this->debug('ObalkyKnihV3 query at URL ' . $queryUrl . ' produced no covers');
            return null;
        }
    }
}
