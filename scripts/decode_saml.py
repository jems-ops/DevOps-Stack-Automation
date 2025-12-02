#!/usr/bin/env python3
"""
SAML Request/Response Decoder
Decodes and pretty-prints SAML requests and responses
"""

import sys
import base64
import zlib
import urllib.parse
import xml.dom.minidom

def decode_saml(encoded_string, is_response=False):
    """
    Decode a SAML request or response

    Args:
        encoded_string: Base64 and URL encoded SAML string
        is_response: True if decoding a SAMLResponse (no deflate), False for SAMLRequest
    """
    try:
        # Step 1: URL decode
        url_decoded = urllib.parse.unquote(encoded_string)
        print("✓ URL decoded")

        # Step 2: Base64 decode
        base64_decoded = base64.b64decode(url_decoded)
        print("✓ Base64 decoded")

        # Step 3: Inflate (decompress) - only for requests, not responses
        if is_response:
            xml_string = base64_decoded.decode('utf-8')
            print("✓ SAMLResponse decoded (no inflation needed)")
        else:
            xml_string = zlib.decompress(base64_decoded, -15).decode('utf-8')
            print("✓ Inflated (decompressed)")

        # Step 4: Pretty print XML
        dom = xml.dom.minidom.parseString(xml_string)
        pretty_xml = dom.toprettyxml(indent="  ")

        print("\n" + "="*80)
        print("DECODED SAML:")
        print("="*80)
        print(pretty_xml)

        return xml_string

    except Exception as e:
        print(f"\n❌ Error decoding: {e}")
        print("\nTrying alternative decoding (as SAMLResponse)...")

        # Try without decompression (might be a response)
        try:
            url_decoded = urllib.parse.unquote(encoded_string)
            base64_decoded = base64.b64decode(url_decoded)
            xml_string = base64_decoded.decode('utf-8')

            dom = xml.dom.minidom.parseString(xml_string)
            pretty_xml = dom.toprettyxml(indent="  ")

            print("\n" + "="*80)
            print("DECODED SAML (as Response):")
            print("="*80)
            print(pretty_xml)

            return xml_string
        except Exception as e2:
            print(f"❌ Alternative decoding also failed: {e2}")
            sys.exit(1)

def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  {} <encoded_saml_string> [--response]".format(sys.argv[0]))
        print("\nExamples:")
        print("  {} 'nVRNb9swDP...' ".format(sys.argv[0]))
        print("  {} 'PHNhbWxwOl...' --response".format(sys.argv[0]))
        print("\nOr pipe from stdin:")
        print("  echo 'nVRNb9swDP...' | {}".format(sys.argv[0]))
        sys.exit(1)

    # Check if input is from stdin
    if not sys.stdin.isatty():
        encoded_saml = sys.stdin.read().strip()
        is_response = '--response' in sys.argv
    else:
        encoded_saml = sys.argv[1]
        is_response = '--response' in sys.argv

    print("Decoding SAML {}...".format("Response" if is_response else "Request"))
    decode_saml(encoded_saml, is_response)

if __name__ == "__main__":
    main()
