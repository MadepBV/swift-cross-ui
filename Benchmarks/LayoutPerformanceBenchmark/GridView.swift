import SwiftCrossUI

struct Column: View {
    var body: some View {
        BodyCounter.record()
        return HStack {
            Color.orange.frame(width: 5)
            Text("Lorem ipsum dolor sit amet.")
        }
    }
}

struct DoubleColumn: View {
    var body: some View {
        BodyCounter.record()
        return HStack {
            Column()
            Column()
        }
    }
}

struct Row: View {
    var body: some View {
        BodyCounter.record()
        return HStack {
            HStack {
                DoubleColumn()
                DoubleColumn()
                DoubleColumn()
                DoubleColumn()
            }
            HStack {
                DoubleColumn()
                DoubleColumn()
                DoubleColumn()
                DoubleColumn()
            }
        }
    }
}

struct DoubleRow: View {
    var body: some View {
        BodyCounter.record()
        return VStack {
            Row()
            Row()
        }
    }
}

struct GridView: TestCaseView {
    var body: some View {
        BodyCounter.record()
        return VStack {
            VStack {
                DoubleRow()
                DoubleRow()
                DoubleRow()
                DoubleRow()
            }
            VStack {
                DoubleRow()
                DoubleRow()
                DoubleRow()
                DoubleRow()
            }
        }
    }
}
