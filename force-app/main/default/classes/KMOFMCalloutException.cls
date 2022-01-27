/**
 * Custom Exception class for OFM callout exceptions
 * Used by webservice callout methods to return exception to aura component in below cases:
 * - Status != 200
 * - Other exceptions
 */
public class KMOFMCalloutException extends Exception {
}