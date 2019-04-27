import requests
import json

headers = {'Content-type': 'application/json;charset=UTF-8'}

data = {
  "transaction": "getTextOfFragment",
  "scroll_version_id": 808,
  "col_id": "9111",
  "SESSION_ID": "8A4254CC-883B-11E8-9BF4-3132E803D4E5"
  }

r = requests.post("https://www.qumranica.org/Scrollery/resources/cgi-bin/scrollery-cgi.pl", json=data, headers=headers)

print("Parsing data.")
json_data = json.loads(r.text)
column = json_data[u'text'][0][u'fragments'][0]
parsed_string = ''
parsed_string_no_reconstructed = ''
parsed_chars = []
parsed_chars_no_reconstructed = []
count = 1
for line in column[u'lines']:
  current_line = []
  current_line_no_reconstructed = []
  for sign in line[u'signs']:
    if (u'attributes' in sign[u'chars'] and u'values' in sign[u'chars'][u'attributes'] and
    u'attribute_value' in sign[u'chars'][u'attributes'][u'values'] and
    sign[u'chars'][u'attributes'][u'values'][u'attribute_value'] == u'SPACE'):
      parsed_string += ' '
      current_line.append(u' ')
      if (u'attributes' not in sign[u'chars'] or u'attribute_name' not in sign[u'chars'][u'attributes'] or
      u'is_reconstructed' not in sign[u'chars'][u'attributes'][u'attribute_name']):
        parsed_string_no_reconstructed += ' '
        current_line_no_reconstructed.append(" ")
    elif (u'sign_char' in sign[u'chars'] and sign[u'chars'][u'sign_char'] != u''):
      if (u'attributes' not in sign[u'chars'] or u'attribute_name' not in sign[u'chars'][u'attributes'] or
      u'is_reconstructed' not in sign[u'chars'][u'attributes'][u'attribute_name']):
        parsed_string_no_reconstructed += sign[u'chars'][u'sign_char']
        current_line_no_reconstructed.append(sign[u'chars'][u'sign_char'])
      parsed_string += sign[u'chars'][u'sign_char']
      current_line.append(sign[u'chars'][u'sign_char'])
  parsed_string += '\n'
  parsed_string_no_reconstructed += '\n'
  parsed_chars.append({line[u'line_name']: current_line})
  parsed_chars_no_reconstructed.append({line[u'line_name']: current_line_no_reconstructed})
  count += 1
print("Parsed string.\n")
print(parsed_string)
print("Dictionary of chars organized by line.\n")
print(parsed_chars)
print("Parsed string with no reconstructed text.\n")
print(parsed_string_no_reconstructed)
print("Dictionary of chars organized by line. No reconstructed text\n")
print(parsed_chars_no_reconstructed)