import Buffer "mo:base/Buffer";
import Array "mo:base/Array";

module {

    public func append<T>(arr1: [T], arr2: [T]): [T] {
        var buffer: Buffer.Buffer<T> = Buffer.Buffer(arr1.size());
        for (it in arr1.vals()) {
            buffer.add(it);
        };
        for (it in arr2.vals()) {
            buffer.add(it);
        };
        return buffer.toArray();
    };
    public func appendAll<T>(arr: [[T]]): [T] {
        var buffer: Buffer.Buffer<T> = Buffer.Buffer(0);
        for (arr1 in arr.vals()) {
            for (it in arr1.vals()) {
                buffer.add(it);
            };
        };
        return buffer.toArray();
    };

}