# Quay Operator

Install the Red Hat Quay operator from the Openshift marketplace:

```
oc apply -f quay-operator
```

Create a `QuayRegistry` object to deploy the several components of the Quay
registry:

```
oc apply -f quay-registry.yml
```

## References

- https://github.com/quay/quay
