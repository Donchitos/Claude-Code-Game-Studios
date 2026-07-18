"use strict";
// Run with:
//   cd functions && npm test
//
// No Java Runtime is available in this environment, so the Firestore/Cloud
// Functions emulator suite cannot run here — this file cannot exercise a
// real end-to-end trigger fire (client deletes a doc -> emulator invokes the
// deployed function -> Firestore is queried for the cascade result). That
// gap is explicitly acknowledged by the story itself ("this is inherently a
// server-side trigger test, not something the client-side test suite can
// fully exercise; note this limitation in the test file itself").
//
// What IS covered, without the emulator:
//   1. cascadeDeleteChildSubcollections — the actual cascade-delete logic,
//      extracted as a plain function and unit-tested here with
//      firebase-admin/firestore mocked via jest.mock (no real Firestore
//      connection, no credentials needed).
//   2. onChildProfileDelete's trigger wiring — verified via the exported
//      CloudFunction's real `.__endpoint` metadata (platform, event type,
//      document path pattern), which firebase-functions populates at module
//      load time regardless of whether the function ever actually runs.
//      Confirmed by direct inspection this metadata is genuine and
//      accurate — not assumed from documentation.
Object.defineProperty(exports, "__esModule", { value: true });
const recursiveDeleteMock = jest.fn().mockResolvedValue(undefined);
jest.mock("firebase-admin/app", () => ({
    initializeApp: jest.fn(),
}));
jest.mock("firebase-admin/firestore", () => ({
    getFirestore: () => ({
        recursiveDelete: recursiveDeleteMock,
    }),
}));
const index_1 = require("../src/index");
describe("cascadeDeleteChildSubcollections", () => {
    beforeEach(() => {
        recursiveDeleteMock.mockClear();
    });
    test("test_cascadeDeleteChildSubcollections_calls_recursiveDelete_with_the_deleted_ref", async () => {
        const fakeRef = { path: "families/parent-1/children/child-1" };
        await (0, index_1.cascadeDeleteChildSubcollections)(fakeRef);
        expect(recursiveDeleteMock).toHaveBeenCalledTimes(1);
        expect(recursiveDeleteMock).toHaveBeenCalledWith(fakeRef);
    });
    test("test_cascadeDeleteChildSubcollections_is_a_no_op_when_ref_is_undefined", async () => {
        await (0, index_1.cascadeDeleteChildSubcollections)(undefined);
        expect(recursiveDeleteMock).not.toHaveBeenCalled();
    });
    test("test_cascadeDeleteChildSubcollections_propagates_a_failed_delete", async () => {
        recursiveDeleteMock.mockRejectedValueOnce(new Error("simulated partial delete failure"));
        const fakeRef = { path: "families/parent-1/children/child-1" };
        await expect((0, index_1.cascadeDeleteChildSubcollections)(fakeRef)).rejects.toThrow("simulated partial delete failure");
    });
});
describe("onChildProfileDelete trigger wiring", () => {
    const endpoint = index_1.onChildProfileDelete.__endpoint;
    test("test_onChildProfileDelete_is_a_2nd_gen_function", () => {
        expect(endpoint.platform).toBe("gcfv2");
    });
    test("test_onChildProfileDelete_listens_for_onDocumentDeleted", () => {
        expect(endpoint.eventTrigger.eventType).toBe("google.cloud.firestore.document.v1.deleted");
    });
    test("test_onChildProfileDelete_watches_the_correct_document_path", () => {
        expect(endpoint.eventTrigger.eventFilterPathPatterns.document).toBe("families/{parentId}/children/{childId}");
    });
});
//# sourceMappingURL=index.test.js.map