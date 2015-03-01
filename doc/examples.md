# Python Client

```python

from pybedquilt import BedquiltClient

client = BedquiltClient()

db = client['test']
people = db['people']

_id = people.insert({
    'name': 'John Doe',
    'age': 22,
    'email': 'johndoe@example.com',
    'likes': [
        'icecream',
        'clowns',
        'puppies'
    ]
})

print _id
# "d9c21dc10fe5a7b5dc606051"

john = people.find_one_by_id(_id)

print john
# {
#     '_id': 'd9c21dc10fe5a7b5dc606051',
#     'name': 'John Doe',
#     'age': 22,
#     'email': 'johndoe@example.com',
#     'likes': [
#         'icecream',
#         'clowns',
#         'puppies'
#     ]
# }

john_again = people.find_one({'email': 'johndoe@example.com'})



```
