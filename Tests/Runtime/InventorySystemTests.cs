using System.Collections.Generic;
using NUnit.Framework;

namespace EnriRanjan.Inventory.Tests
{
    /// <summary>
    /// Plain NUnit tests for the noEngineReferences runtime assembly.
    /// No UnityTest / coroutines here on purpose: code under
    /// EnriRanjan.Inventory must stay engine-free and testable with
    /// pure NUnit, without needing PlayMode.
    /// </summary>
    public class InventorySystemTests
    {
        private const string Lantern = "lantern";
        private const string Crowbar = "crowbar";
        private const string Locket = "locket";

        [Test]
        public void AddAndRemove_UpdateSlotsCountAndRaiseEvents()
        {
            var inventory = new InventorySystem<string>(3);
            var added = new List<(string id, int slot)>();
            var removed = new List<(string id, int slot)>();
            inventory.ItemAdded += (id, slot) => added.Add((id, slot));
            inventory.ItemRemoved += (id, slot) => removed.Add((id, slot));

            Assert.IsTrue(inventory.TryAdd(Lantern, out int lanternSlot));
            Assert.IsTrue(inventory.TryAdd(Crowbar, out int crowbarSlot));
            Assert.AreEqual(0, lanternSlot);
            Assert.AreEqual(1, crowbarSlot);
            Assert.AreEqual(2, inventory.Count);
            Assert.IsTrue(inventory.Contains(Lantern));
            Assert.AreEqual(Lantern, inventory.Slots[0].Item);
            Assert.AreEqual(Crowbar, inventory.Slots[1].Item);
            Assert.IsFalse(inventory.Slots[2].HasItem);
            Assert.AreEqual(new[] { (Lantern, 0), (Crowbar, 1) }, added);

            Assert.IsTrue(inventory.TryRemove(Lantern));
            Assert.AreEqual(1, inventory.Count);
            Assert.IsFalse(inventory.Contains(Lantern));
            Assert.IsFalse(inventory.Slots[0].HasItem);
            Assert.AreEqual(new[] { (Lantern, 0) }, removed);
        }

        [Test]
        public void TryAdd_WhenFull_ReturnsFalseAndRaisesNoEvent()
        {
            var inventory = new InventorySystem<string>(1);
            inventory.TryAdd(Lantern, out _);
            var added = new List<string>();
            inventory.ItemAdded += (id, slot) => added.Add(id);

            Assert.IsTrue(inventory.IsFull);
            Assert.IsFalse(inventory.TryAdd(Crowbar, out int slot));
            Assert.AreEqual(-1, slot);
            Assert.IsEmpty(added);
            Assert.AreEqual(1, inventory.Count);
        }

        [Test]
        public void TryRemove_UnknownId_ReturnsFalse()
        {
            var inventory = new InventorySystem<string>(2);
            inventory.TryAdd(Lantern, out _);

            Assert.IsFalse(inventory.TryRemove(Locket));
            Assert.AreEqual(1, inventory.Count);
        }

        [Test]
        public void Slots_KeepPosition_AndAddReusesFirstFreeSlot()
        {
            var inventory = new InventorySystem<string>(3);
            inventory.TryAdd(Lantern, out _);
            inventory.TryAdd(Crowbar, out _);
            inventory.TryAdd(Locket, out _);

            Assert.IsTrue(inventory.TryRemoveAt(1));
            Assert.AreEqual(Lantern, inventory.Slots[0].Item, "Removing must not shift the other slots.");
            Assert.IsFalse(inventory.Slots[1].HasItem);
            Assert.AreEqual(Locket, inventory.Slots[2].Item);

            Assert.IsTrue(inventory.TryAdd(Crowbar, out int slot));
            Assert.AreEqual(1, slot, "A later add must take the first free slot.");
            Assert.AreEqual(Crowbar, inventory.Slots[1].Item);
        }
    }
}
