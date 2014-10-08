﻿using System.Collections.Generic;
using System.Threading.Tasks;

using Chill.StateBuilders;
using Chill.Tests.TestSubjects;

using FluentAssertions;

using Xunit;

namespace Chill.Tests
{
    public class StateBuilderSpecs : GivenWhenThen
    {
        TestClass expectedTestClass = new TestClass();

        [Fact]
        public void When_setting_items_directly_then_it_should_be_found()
        {
            When(() => UseThe(expectedTestClass));
        }



        [Fact]
        public void When_setting_testclass_in_container_then_it_should_be_found()
        {
            When(() => SetThe<TestClass>().To(expectedTestClass));

            The<TestClass>().Should().Be(expectedTestClass);
        }
        public class Given_several_testclasses_in_the_container : GivenWhenThen
        {
            public Given_several_testclasses_in_the_container()
            {
                Given(() =>
                {
                    SetThe<TestClass>().AtIndex(1).To(new TestClass() { Name = "1" });
                    SetThe<TestClass>().AtIndex(0).To(new TestClass() { Name = "0" });
                    SetThe<TestClass>().Named("name").To(new TestClass() { Name = "named" });
                });
            }

            [Fact]
            public void Then_testclasses_should_be_found_as_list()
            {
                The<List<TestClass>>().Count.Should().Be(3);
            }

            [Fact]
            public void Then_testclasses_should_be_found_at_correct_indexes()
            {
                The<TestClass>(atIndex: 1).Name.Should().Be("1");
                The<TestClass>(atIndex: 0).Name.Should().Be("0");
            }

            [Fact]
            public void then_named_testclass_is_present()
            {
                The<TestClass>(named: "name").Name.Should().Be("named");
            }
        }
    }


}